import 'dart:io';

import 'package:edu_chatbot/data/gemini/gemini_response.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/exam_link.dart';

class PdfMakerService {

  /// This method takes a page format and generates the Pdf file data
  Future<File> buildPdf(
      {required ExamLink examLink,
      required MyGeminiResponse geminiResponse}) async {
    // Create the Pdf document
    final pw.Document doc = pw.Document();

    // Add one page with centered text "Hello World"
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.ConstrainedBox(
            constraints: const pw.BoxConstraints.expand(),
            child: pw.FittedBox(
              child: pw.Text(
                '${examLink.subject!.title}',
                style: pw.TextStyle(
                  color: PdfColors.black,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );

    // Build and return the final Pdf file data
    var bytes = await doc.save();
    final appDir = await getApplicationDocumentsDirectory();
    var filePath = 'pdf_${DateTime.now().toIso8601String()}.pdf';
    final file = File('${appDir.path}/$filePath');

    return file;
  }
}
