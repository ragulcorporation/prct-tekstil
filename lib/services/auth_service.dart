import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. STREAM STATUS LOGIN (Memantau sesi secara Real-Time)
  // Fungsi ini akan memberi tahu aplikasi secara instan jika user login atau logout
  Stream<User?> get streamStatusAuth => _auth.authStateChanges();

  // 2. FUNGSI LOGIN (Menggunakan Email & Password Karyawan)
  Future<UserCredential> loginDenganEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Menembak data ke Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Menangkap error spesifik dari Firebase (misal: password salah)
      // Fungsi untuk mendaftarkan operator baru ke Firebase Auth
  Future<UserCredential> registerDenganEmail({required String email, required String password}) async {
    try {
      return await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Gagal registrasi: $e');
    }
  }
      if (e.code == 'user-not-found') {
        throw Exception('Email tidak terdaftar di sistem pabrik.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Password yang Anda masukkan salah.');
      }
      throw Exception(e.message ?? 'Terjadi kesalahan saat login.');
    } catch (e) {
      throw Exception('Gagal terhubung ke server auth: $e');
    }
  }

  // 3. FUNGSI LOGOUT
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Gagal melakukan logout: $e');
    }
  }

  // 4. MENGAMBIL DATA USER YANG SEDANG AKTIF
  User? get userSekarang => _auth.currentUser;
}