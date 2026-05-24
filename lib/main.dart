import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // WAJIB: Import inti Firebase
import 'package:k_tech/firebase_options.dart';     // WAJIB: Kunci KTP Firebase Anda
import 'package:k_tech/features/dashboard/presentation/screens/dashboard_screen.dart';

// ==================== FUNGSI UTAMA (BOOTING) ====================
void main() async {
  // 1. Tahan aplikasi agar tidak langsung menggambar UI
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Nyalakan mesin Firebase sebelum aplikasi berjalan
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Setelah Firebase siap, baru jalankan aplikasi
  runApp(const MyApp());
}

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
      
      // ================= DARK THEME CONFIG (PREMIUM INDUSTRIAL) =================
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          primary: const Color(0xFF3B82F6),   
          secondary: const Color(0xFF60A5FA), 
          surface: const Color(0xFF1E293B),   
          // ignore: deprecated_member_use
          background: const Color(0xFF0F172A),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardTheme: const CardThemeData(
          color: Color(0xFF1E293B),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
        ),
      ),
      home: const DashboardScreen(), 
    );
  }
}

// ================= GLOBAL STATE (CADANGAN LOKAL) =================
// Catatan: Sebagian besar data ini sekarang sudah diambil alih oleh Firestore, 
// tapi kita tetap pertahankan untuk mencegah error/crash pada saat loading awal.
class AppState {
  static bool isLoggedIn = false;
  static String currentWorker = "Operator/Tamu";
  
  static List<Map<String, dynamic>> logProduksi = [];

  static List<Map<String, dynamic>> mesinList = [
    {'id': 'MSN-01', 'nama': 'Mesin Rajut Sektor A', 'status': 'Active', 'terakhir_maintenance': DateTime.now()},
  ];

  static List<Map<String, dynamic>> jenisKainList = [
    {'kode': 'EIGER11', 'nama': 'Katun Combed', 'warna': 'Blue'},
    {'kode': 'KHTX01', 'nama': 'Polyester Filament', 'warna': 'White'},
  ];
  
  static List<Map<String, String>> karyawanList = [];
}