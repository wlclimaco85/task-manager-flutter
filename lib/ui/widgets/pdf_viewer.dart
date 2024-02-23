import 'package:easy_pdf_viewer/easy_pdf_viewer.dart';
import 'package:flutter/material.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  const PdfViewerScreen({Key? key, required this.pdfUrl}) : super(key: key);
  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  PDFDocument? document;

  void initializePdf() async {
    document = await PDFDocument.fromURL(widget.pdfUrl);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    initializePdf();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffbff00),
        flexibleSpace: Container(
            decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orangeAccent, Colors.orangeAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        )),
        title: const Text('Deneme'),
      ),
      body: document != null
          ? Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orangeAccent, Colors.orangeAccent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: PDFViewer(
                document: document!,
                lazyLoad: false,
                zoomSteps: 3,
                scrollDirection: Axis.vertical,
                backgroundColor: Colors.transparent,
                indicatorPosition: IndicatorPosition.bottomLeft,
              ),
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
