import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/localization/failure_message.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/shake.dart';
import '../../../../core/widgets/status_message.dart';
import '../cubits/scan_cubit.dart';
import '../cubits/scan_state.dart';
import '../widgets/demo_codes_sheet.dart';
import '../widgets/scan_viewfinder.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key, this.demoCodes = const []});

  final List<String> demoCodes;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  static const double _windowCenter = 0.42;
  static const double _windowScale = 0.68;

  static const List<BarcodeFormat> _formats = [BarcodeFormat.qrCode];

  final ImagePicker _imagePicker = ImagePicker();

  final MobileScannerController _controller = MobileScannerController(formats: _formats);

  late final AppLifecycleListener _lifecycle;

  Rect _windowFor(Size size) {
    final side = min(size.width, size.height) * _windowScale;
    return Rect.fromCenter(center: Offset(size.width / 2, size.height * _windowCenter), height: side, width: side);
  }

  Widget _cameraProblem(BuildContext context, MobileScannerException error) {
    final isDenied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: context.colors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: StatusMessage(
            body: context.tr(isDenied ? LocaleKeys.scanCameraDeniedBody : LocaleKeys.scanCameraUnavailableBody),
            icon: Icons.no_photography_rounded,
            title: context.tr(isDenied ? LocaleKeys.scanCameraDeniedTitle : LocaleKeys.scanCameraUnavailableTitle),
          ),
        ),
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    final payload = capture.barcodes.firstOrNull?.rawValue;
    if (payload != null) unawaited(context.read<ScanCubit>().codeDetected(payload));
  }

  Widget _status(BuildContext context, ScanState state) {
    final colors = context.colors;
    final failure = state.failure;
    if (failure != null) {
      return Shake(
        key: const ValueKey(LocaleKeys.scanAgain),
        trigger: state.errorToken,
        child: AppPressable(
          onPressed: context.read<ScanCubit>().dismissFailure,
          child: _StatusPill(
            leading: Icon(Icons.error_rounded, color: colors.danger, size: AppSpacing.iconSm),
            trailing: Text(
              context.tr(LocaleKeys.scanAgain),
              maxLines: 1,
              style: AppTextStyles.label.copyWith(color: colors.accentInk, fontWeight: FontWeight.w600),
            ),
            child: Text(context.failureMessage(failure), style: AppTextStyles.label.copyWith(color: colors.textPrimary)),
          ),
        ),
      );
    }
    if (state.isResolving || state.hasResult) {
      return _StatusPill(
        key: const ValueKey(LocaleKeys.scanResolving),
        leading: const AppLoader(),
        child: Text(
          context.tr(LocaleKeys.scanResolving),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.label.copyWith(color: colors.textPrimary),
        ),
      );
    }
    return Text(
      context.tr(LocaleKeys.scanHint),
      key: const ValueKey(LocaleKeys.scanHint),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.label.copyWith(color: colors.textSecondary),
      textAlign: TextAlign.center,
    );
  }

  Future<void> _pickImage() async {
    final cubit = context.read<ScanCubit>();
    final XFile? image;
    try {
      image = await _imagePicker.pickImage(source: ImageSource.gallery);
    } on PlatformException {
      return;
    }
    if (image == null) return;
    final payload = await _decodeImage(image.path);
    if (!mounted) return;
    _resume();
    if (payload == null) {
      cubit.imageHadNoCode();
    } else {
      await cubit.codeSelected(payload);
    }
  }

  Future<String?> _decodeImage(String path) async {
    try {
      return (await _controller.analyzeImage(path, formats: _formats))?.barcodes.firstOrNull?.rawValue;
    } on MobileScannerBarcodeException {
      return null;
    }
  }

  Future<void> _openMyQr() async {
    _pause();
    await context.push<void>(AppRoutes.myQr);
    if (mounted) _resume();
  }

  Future<void> _showDemoCodes() async {
    final cubit = context.read<ScanCubit>();
    final payload = await showAppSheet<String>(context, child: DemoCodesSheet(codes: widget.demoCodes));
    if (!mounted) return;
    _resume();
    if (payload != null) await cubit.codeSelected(payload);
  }

  Future<void> _open(ScanState state) async {
    final cubit = context.read<ScanCubit>();
    final draft = state.draft;
    _pause();
    if (draft != null) {
      await context.push<void>(AppRoutes.payReview, extra: draft);
    } else {
      await context.push<void>(AppRoutes.payAmount, extra: state.recipient);
    }
    if (!mounted) return;
    cubit.clearResult();
    _resume();
  }

  void _pause() {
    if (_controller.value.hasCameraPermission) unawaited(_controller.stop());
  }

  void _resume() {
    final value = _controller.value;
    if (mounted && value.hasCameraPermission && (ModalRoute.of(context)?.isCurrent ?? false) && !value.isRunning && !value.isStarting) unawaited(_controller.start());
  }

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onInactive: _pause, onResume: _resume);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: AppTheme.dark,
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: BlocConsumer<ScanCubit, ScanState>(
        builder: (context, state) {
          final colors = context.colors;
          return Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final window = _windowFor(constraints.biggest);
                      return MobileScanner(
                        controller: _controller,
                        errorBuilder: _cameraProblem,
                        onDetect: _onDetect,
                        overlayBuilder: (context, constraints) => ScanViewfinder(window: window),
                        placeholderBuilder: (context) => ColoredBox(color: colors.background),
                        scanWindow: window,
                        useAppLifecycleState: false,
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const AppBackButton(),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(context.tr(LocaleKeys.scanTitle), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.title),
                            ),
                            ValueListenableBuilder<MobileScannerState>(
                              builder: (context, value, _) => switch (value.torchState) {
                                TorchState.unavailable => const SizedBox.shrink(),
                                TorchState.on => AppIconButton(icon: Icons.flashlight_off_rounded, onPressed: () => unawaited(_controller.toggleTorch()), semanticLabel: context.tr(LocaleKeys.scanTorchOff)),
                                TorchState.auto || TorchState.off => AppIconButton(icon: Icons.flashlight_on_rounded, onPressed: () => unawaited(_controller.toggleTorch()), semanticLabel: context.tr(LocaleKeys.scanTorchOn)),
                              },
                              valueListenable: _controller,
                            ),
                          ],
                        ),
                        const Spacer(),
                        AnimatedSwitcher(duration: AppMotion.base, child: _status(context, state)),
                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ScanAction(icon: Icons.photo_library_rounded, label: context.tr(LocaleKeys.scanGallery), onPressed: state.isResolving ? null : () => unawaited(_pickImage())),
                            _ScanAction(icon: Icons.qr_code_2_rounded, label: context.tr(LocaleKeys.scanMyQr), onPressed: () => unawaited(_openMyQr())),
                            if (widget.demoCodes.isNotEmpty) _ScanAction(icon: Icons.science_rounded, label: context.tr(LocaleKeys.scanDemo), onPressed: state.isResolving ? null : () => unawaited(_showDemoCodes())),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        listener: (context, state) => unawaited(_open(state)),
        listenWhen: (previous, current) => current.hasResult && !previous.hasResult,
      ),
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({super.key, required this.child, required this.leading, this.trailing});

  final Widget child;
  final Widget leading;

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.lg), color: context.colors.surfaceRaised),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: AppSpacing.md),
          Flexible(child: child),
          if (trailing != null) ...[const SizedBox(width: AppSpacing.md), trailing],
        ],
      ),
    );
  }
}

class _ScanAction extends StatelessWidget {
  const _ScanAction({required this.label, required this.icon, this.onPressed});

  final String label;

  final IconData icon;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      child: AppPressable(
        onPressed: onPressed,
        child: AnimatedOpacity(
          duration: AppMotion.fast,
          opacity: onPressed == null ? AppMotion.disabledOpacity : 1,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(color: colors.surfaceRaised, shape: BoxShape.circle),
                height: AppSpacing.controlHeight,
                width: AppSpacing.controlHeight,
                child: Icon(icon, color: colors.textPrimary, size: AppSpacing.iconMd),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(color: colors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
