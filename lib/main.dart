import 'package:flutter/material.dart';
import 'package:k_tech/features/dashboard/presentation/screens/dashboard_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
  
  // Fungsi statis global untuk memicu perubahan tema dari screen mana saja
  static _MyAppState? of(BuildContext context) => context.findAncestorStateOfType<_MyAppState>();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'K-Tech Textile MES',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      
      // ================= LIGHT THEME CONFIG =================
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          primary: const Color(0xFF1E3A8A),   
          secondary: const Color(0xFF0284C7), 
          surface: Colors.white,              
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
        ),
      ),
      
      // ================= DARK THEME CONFIG (PREMIUM TEXTILE INDUSTRIAL) =================
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          primary: const Color(0xFF3B82F6),   
          secondary: const Color(0xFF60A5FA), 
          surface: const Color(0xFF1E293B),   
          background: const Color(0xFF0F172A),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardTheme: const CardThemeData(
          color: const Color(0xFF1E293B),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
        ),
      ),
      home: const DashboardScreen(), // Otomatis mengontrol fase Welcome di awal
    );
  }
}

// ================= GLOBAL STATE MES PABRIK KAIN KAHATEX STYLE =================
class AppState {
  static bool isLoggedIn = false; 
  static String currentWorker = "Tamu/Operator"; 

  // Master Data Karyawan Terregistrasi
  static List<Map<String, String>> karyawanList = [
    {'username': 'agha', 'nama': 'Agha Gha', 'pin': '1234'},
    {'username': 'operator1', 'nama': 'Budi Santoso', 'pin': '0000'},
  ];

  // Master Data Mesin dengan Sektor Pabrik
  static List<Map<String, dynamic>> mesinList = [
    {'id': 'MSN-01', 'nama': 'Mesin Rajut Circular A (Weaving Dept)', 'status': 'Produksi', 'terakhir_maintenance': DateTime(2026, 5, 12)},
    {'id': 'MSN-02', 'nama': 'Mesin Rajut Circular B (Weaving Dept)', 'status': 'Standby', 'terakhir_maintenance': DateTime(2026, 5, 18)},
    {'id': 'MSN-03', 'nama': 'Mesin Tenun Loom 01 (Knitting Dept)', 'status': 'Produksi', 'terakhir_maintenance': DateTime(2026, 4, 15)},
  ];

  // Master Data Jenis Kain Berkode Khusus & Warna Thread
  static List<Map<String, String>> jenisKainList = [
    {'kode': 'EIGER11', 'nama': 'Katun Combed', 'warna': 'Red'},
    {'kode': 'EIGER11', 'nama': 'Katun Combed', 'warna': 'Blue'},
    {'kode': 'POLY02', 'nama': 'Poliester Premium', 'warna': 'Black'},
  ];

  // Log Hasil Input Laporan Produksi
  static List<Map<String, dynamic>> logProduksi = [
    {
      'tanggal': DateTime(2026, 5, 23),
      'waktu': '14:32',
      'shift': 'Shift 2',
      'operator': 'Agha Gha', 
      'mesin_id': 'MSN-01',   
      'jenis_kain': 'EIGER11 - Red',
      'berat': 83.5,
      'status': 'Bagus',
      'cacat': '',
    },
    {
      'tanggal': DateTime(2026, 5, 23),
      'waktu': '16:15',
      'shift': 'Shift 2',
      'operator': 'Agha Gha', 
      'mesin_id': 'MSN-01',   
      'jenis_kain': 'EIGER11 - Blue',
      'berat': 103.5,
      'status': 'Bagus',
      'cacat': '',
    },
  ];
}