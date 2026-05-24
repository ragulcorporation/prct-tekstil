import 'package:flutter/material.dart';
// IMPORT DIPERBAIKI: Kembali menggunakan file yang sudah punya urat nadi Firebase
import 'package:k_tech/features/produksi/presentation/screens/input_produksi_screen.dart';

class InputManagementScreen extends StatelessWidget {
  final VoidCallback onAddMasterTap;

  const InputManagementScreen({
    super.key,
    required this.onAddMasterTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fasilitas Input & Registrasi Sektor',
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold, 
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih opsi di bawah untuk memperbarui data lantai produksi PT Kahatex ke dalam Cloud Server.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 24),

            // ==================== OPSI 1: PENCATATAN KAIN (FIREBASE READY) ====================
            _buildMenuCard(
              title: 'Pencatatan Hasil Kain (Manual/SCAN QR)',
              subtitle: 'Input berat roll garmen, shift kerja, dan jalur lintasan aktif ke server pusat.',
              icon: Icons.assignment_outlined,
              iconColor: const Color(0xFF3B82F6),
              isDark: isDark,
              onTap: () {
                // SINKRONISASI SEMPURNA: Masuk ke form yang sudah ada StreamBuilder Firebasenya!
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InputProduksiScreen()),
                );
              },
            ),
            const SizedBox(height: 16),

            // ==================== OPSI 2: REGISTRASI DATA MASTER (FIREBASE READY) ====================
            _buildMenuCard(
              title: 'Registrasi Mesin / Konstruksi Kain',
              subtitle: 'Tambah ID alat baru atau spesifikasi varian benang master ke Firestore.',
              icon: Icons.playlist_add_circle_outlined,
              iconColor: const Color(0xFF10B981),
              isDark: isDark,
              onTap: onAddMasterTap, // Memicu callback fungsi dialog master di otak dashboard_screen
            ),
          ],
        ),
      ),
    );
  }

  // Komponen Kartu Menu yang Bersih
  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black87 : Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }
}