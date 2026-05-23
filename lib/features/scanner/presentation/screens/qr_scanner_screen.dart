import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:k_tech/features/produksi/presentation/screens/input_produksi_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool isScanCompleted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR Code Mesin", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E40AF),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Widget kamera pemindai langsung terintegrasi penuh
          MobileScanner(
            onDetect: (capture) {
              if (!isScanCompleted) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final String code = barcode.rawValue ?? "MSN-01";
                  setState(() { isScanCompleted = true; });
                  
                  // Mengunci kode QR mesin, lompat langsung ke form karyawan
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InputProduksiScreen(mesinIdFromQR: code),
                    ),
                  );
                }
              }
            },
          ),
          // Desain Kotak Pembidik Bidik Tengah Ala QRIS Bank
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent, width: 4),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          const Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: Text(
              "Arahkan Kamera HP Tepat Pada QR Code Mesin",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, backgroundColor: Colors.black54, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }
}