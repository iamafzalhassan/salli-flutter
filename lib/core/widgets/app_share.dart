import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

export 'package:share_plus/share_plus.dart' show XFile;

Future<void> shareContent(BuildContext context, {List<XFile>? files, String? text}) async {
  final box = context.findRenderObject();
  final origin = box is RenderBox && box.hasSize ? box.localToGlobal(Offset.zero) & box.size : null;
  await SharePlus.instance.share(ShareParams(files: files, sharePositionOrigin: origin, text: text));
}
