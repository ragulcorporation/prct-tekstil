import 'package:flutter/material.dart';
import 'package:k_tech/features/dashboard/presentation/screens/dashboard_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'K-Tech Textile MES',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF172554), // Navy Gelap
          primary: const Color(0xFF1E40AF),   
          secondary: const Color(0xFF3B82F6), 
          surface: Colors.white,              
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), 
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0, // Flat design agar lebih bersih
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

class AppState {
  static bool isLoggedIn = false; 

  // DAFTAR MESIN (Sekarang bisa ditambah)
  static List<Map<String, dynamic>> mesinList = [
    {'id': 'MSN-01', 'nama': 'Mesin Rajut Circular A', 'status': 'Produksi', 'terakhir_maintenance': DateTime(2026, 5, 12)},
    {'id': 'MSN-02', 'nama': 'Mesin Rajut Circular B', 'status': 'Standby', 'terakhir_maintenance': DateTime(2026, 5, 18)},
    {'id': 'MSN-03', 'nama': 'Mesin Tenun Loom 01', 'status': 'Produksi', 'terakhir_maintenance': DateTime(2026, 4, 15)},
  ];

  // DAFTAR JENIS KAIN (Sekarang bisa ditambah)
  static List<String> jenisKainList = ['Katun Combed', 'Poliester', 'Fleece', 'Spandex', 'Pique'];

  static List<Map<String, dynamic>> logProduksi = [
    {'tanggal': DateTime(2026, 5, 23), 'waktu': '14:32', 'shift': 'Shift 2', 'mesin_id': 'MSN-01', 'jenis_kain': 'Katun Combed', 'berat': 83.5, 'status': 'Bagus', 'cacat': ''},
  ];
}