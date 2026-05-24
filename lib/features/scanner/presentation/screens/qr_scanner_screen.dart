import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:k_tech/features/produksi/presentation/screens/form_produksi_screen.dart'; // Import Form Manual

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _isProcessingScan = false;
  bool _isTorchOn = false; 
  final MobileScannerController _cameraController = MobileScannerController();

  @override
  void dispose() {
    _cameraController.dispose(); // Wajib dimatikan agar memori HP tidak bocor
    super.dispose();
  }

  // Verifikasi Firebase sebelum masuk ke form
  Future<void> _onQRCodeDetected(String scannedData) async {
    if (_isProcessingScan) return;
    
    // Anti-Crash: Tolak QR Code berupa link website (Bungkus makanan, URL, dll)
    if (scannedData.contains('http') || scannedData.contains('/')) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR Ditolak: Format bukan ID Mesin Pabrik!'), backgroundColor: Colors.red)
        );
      }
      return;
    }

    setState(() => _isProcessingScan = true);
    String mesinTerpilih = scannedData.trim().toUpperCase();

    try {
      // Tembak ke server Cloud Firestore untuk cek apakah mesin tersebut valid
      final docMesin = await FirebaseFirestore.instance.collection('mesin').doc(mesinTerpilih).get();

      if (docMesin.exists && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.green, duration: const Duration(seconds: 1), content: Text('Mesin Valid: $mesinTerpilih'))
        );
        
        // Tutup kamera dan lempar ID Mesin ke Form Pencatatan Manual
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => FormProduksiScreen(scannedMesinId: mesinTerpilih)),
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR Ditolak: Mesin tidak terdaftar di Server!'), backgroundColor: Colors.red)
          );
        }
        setState(() => _isProcessingScan = false); 
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal koneksi ke server: $e'), backgroundColor: Colors.red));
      }
      setState(() => _isProcessingScan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E40AF), 
        title: const Text('Scan QR Code Mesin', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [
          // Tombol Senter (Flashlight)
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off, color: _isTorchOn ? Colors.amber : Colors.white),
            onPressed: () {
              setState(() => _isTorchOn = !_isTorchOn);
              _cameraController.toggleTorch(); 
            },
          ),
        ],
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. KAMERA FISIK ASLI 
          Positioned.fill(
            child: MobileScanner(
              controller: _cameraController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                  _onQRCodeDetected(barcodes.first.rawValue!); 
                }
              },
            ),
          ),
          
          // 2. KOTAK BIDIK BIRU NEON
          Center(
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFF3B82F6), width: 3), borderRadius: BorderRadius.circular(32)),
            ),
          ),
          
          // 3. TEKS PETUNJUK
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(4)),
                child: Text(_isProcessingScan ? 'Memverifikasi Server...' : 'Arahkan Kamera HP Tepat Pada QR Code Mesin', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
              ),
            ),
          ),
          
          // 4. LOADING INDICATOR
          if (_isProcessingScan)
            const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
        ],
      ),
    );
  }
}