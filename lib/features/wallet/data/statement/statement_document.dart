import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/lkr_format.dart';
import '../../../../core/utils/money.dart';
import '../../domain/entities/wallet_transaction.dart';

class StatementDocument {
  static const double _cellPadding = 6;
  static const double _gap = 16;
  static const double _margin = 36;
  static const double _smallText = 9;
  static const double _textSize = 10;
  static const double _titleSize = 20;

  static const String _asciiMinus = '-';
  static const String _locale = 'en_US';
  static const String _placeholder = '{}';
  static const String _translations = 'assets/translations/en.json';

  static const PdfColor _accent = PdfColor.fromInt(0xFFE7FF5F);
  static const PdfColor _ink = PdfColor.fromInt(0xFF030301);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B6868);
  static const PdfColor _rule = PdfColor.fromInt(0xFFE2E2DA);

  const StatementDocument();

  Future<Uint8List> build({required DateTime from, required String holder, required String phone, required DateTime to, required List<WalletTransaction> transactions}) async {
    final strings = jsonDecode(await rootBundle.loadString(_translations)) as Map<String, dynamic>;
    String text(String key, [List<String> args = const []]) => args.fold(key.split('.').fold<Object?>(strings, (node, part) => (node as Map<String, dynamic>?)?[part]) as String? ?? key, (text, arg) => text.replaceFirst(_placeholder, arg));
    String money(String formatted) => formatted.replaceAll(LkrFormat.minusSign, _asciiMinus);
    final symbol = text('currency.symbol');
    final dates = DateFormat.yMMMd(_locale);
    final moneyIn = transactions.where((transaction) => transaction.amount.isPositive).fold(Money.zero, (sum, transaction) => sum + transaction.amount);
    final moneyOut = transactions.where((transaction) => transaction.amount.isNegative).fold(Money.zero, (sum, transaction) => sum + transaction.amount.abs());
    const bodyStyle = pw.TextStyle(color: _ink, fontSize: _textSize);
    const mutedStyle = pw.TextStyle(color: _muted, fontSize: _textSize);
    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: pw.Font.helvetica(), bold: pw.Font.helveticaBold()),
      title: text('statement.title'),
    );
    document.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Container(
            color: _accent,
            padding: const pw.EdgeInsets.all(_gap),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  text('statement.brand'),
                  style: const pw.TextStyle(color: _ink, fontSize: _titleSize, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  text('statement.title'),
                  style: const pw.TextStyle(color: _ink, fontSize: _textSize, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: _gap),
          pw.Text(
            holder,
            style: const pw.TextStyle(color: _ink, fontSize: _textSize, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(phone, style: mutedStyle),
          pw.Text(text('statement.period', [dates.format(from), dates.format(to.subtract(const Duration(days: 1)))]), style: mutedStyle),
          pw.SizedBox(height: _gap),
          pw.Row(
            children: [
              pw.Expanded(child: pw.Text(text('statement.moneyIn', [money(LkrFormat.withSymbol(moneyIn, symbol))]), style: bodyStyle)),
              pw.Expanded(child: pw.Text(text('statement.moneyOut', [money(LkrFormat.withSymbol(moneyOut, symbol))]), style: bodyStyle)),
            ],
          ),
          pw.SizedBox(height: _gap),
          if (transactions.isEmpty)
            pw.Text(text('statement.empty'), style: mutedStyle)
          else
            pw.TableHelper.fromTextArray(
              border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: _rule)),
              cellAlignments: {3: pw.Alignment.centerRight},
              cellPadding: const pw.EdgeInsets.all(_cellPadding),
              cellStyle: const pw.TextStyle(color: _ink, fontSize: _smallText),
              data: [
                for (final transaction in transactions) [dates.format(transaction.createdAt.toLocal()), transaction.counterpartyName, text('transaction.${transaction.type.name}'), money(LkrFormat.signed(transaction.amount, symbol))],
              ],
              headerDecoration: const pw.BoxDecoration(color: _rule),
              headers: [text('statement.date'), text('statement.description'), text('statement.kind'), text('statement.amount')],
              headerStyle: const pw.TextStyle(color: _ink, fontSize: _smallText, fontWeight: pw.FontWeight.bold),
            ),
          pw.SizedBox(height: _gap),
          pw.Text(
            text('statement.footer'),
            style: const pw.TextStyle(color: _muted, fontSize: _smallText),
          ),
        ],
        margin: const pw.EdgeInsets.all(_margin),
        pageFormat: PdfPageFormat.a4,
      ),
    );
    return document.save();
  }
}
