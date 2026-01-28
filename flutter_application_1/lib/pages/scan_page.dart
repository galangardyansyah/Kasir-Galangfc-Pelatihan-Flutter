import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Produk')),
      body: MobileScanner(
        controller: MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
        ),
        onDetect: (barcodeCapture) {
          final barcode = barcodeCapture.barcodes.first;
          final String? value = barcode.rawValue;

          if (value != null) {
            Navigator.pop(context, value);
          }
        },
      ),
    );
  }
}
