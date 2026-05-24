import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // Variabel _db ini adalah "kunci utama", semua fungsi di bawah harus ada di dalam kurung kurawal class ini
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==========================================
  // 1. BAGIAN MESIN
  // ==========================================
  Stream<List<Map<String, dynamic>>> streamMesin() {
    return _db.collection('mesin').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'nama': data['nama_mesin'] ?? 'Mesin Tanpa Nama',
          'status': data['status'] ?? 'Standby',
          'terakhir_maintenance': (data['terakhir_maintenance'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    });
  }

  Future<void> tambahMesinBaru(String idMesin, String namaMesin) async {
    try {
      await _db.collection('mesin').doc(idMesin).set({
        'nama_mesin': namaMesin,
        'status': 'Standby',
        'terakhir_maintenance': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal menambah mesin: $e');
    }
  }

  // ==========================================
  // 2. BAGIAN PRODUKSI LOG
  // ==========================================
  Stream<List<Map<String, dynamic>>> streamLogProduksiHariIni() {
    final hariIni = DateTime.now();
    final awalHari = DateTime(hariIni.year, hariIni.month, hariIni.day);

    return _db
        .collection('produksi_log')
        .where('timestamp', isGreaterThanOrEqualTo: awalHari)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id_log': doc.id,
          'mesin_id': data['id_mesin'] ?? '',
          'jenis_kain': data['jenis_kain'] ?? '',
          'berat': data['berat'] ?? 0.0,
          'status': data['ada_cacat'] == true ? 'Cacat' : 'Bagus',
          'waktu': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    });
  }

  Future<void> simpanLogProduksi({
    required String idMesin,
    required String jenisKain,
    required double berat,
    required bool adaCacat,
    required String detailCacat,
  }) async {
    try {
      await _db.collection('produksi_log').add({
        'timestamp': FieldValue.serverTimestamp(),
        'shift': 'Shift Aktif', 
        'id_mesin': idMesin,
        'jenis_kain': jenisKain,
        'berat': berat,
        'ada_cacat': adaCacat,
        'detail_cacat': detailCacat,
        'operator': 'Operator Sistem', 
      });
    } catch (e) {
      throw Exception('Gagal menyimpan log produksi: $e');
    }
  }

  // ==========================================
  // 3. BAGIAN MAINTENANCE (SEKARANG SUDAH AMAN DI DALAM CLASS)
  // ==========================================
  Stream<List<Map<String, dynamic>>> streamAlarmMaintenance() {
    final batasWaktu = DateTime.now().subtract(const Duration(days: 30));

    return _db
        .collection('mesin')
        .where('terakhir_maintenance', isLessThanOrEqualTo: batasWaktu)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'nama': doc.data()['nama_mesin'] ?? 'Mesin Tanpa Nama',
          'status': doc.data()['status'] ?? 'Standby',
          'terakhir_maintenance': (doc.data()['terakhir_maintenance'] as Timestamp?)?.toDate(),
        };
      }).toList();
    });
  }

  Future<void> resetJadwalMaintenance(String idMesin) async {
    try {
      await _db.collection('mesin').doc(idMesin).update({
        'terakhir_maintenance': FieldValue.serverTimestamp(),
        'status': 'Standby',
      });
    } catch (e) {
      throw Exception('Gagal mereset jadwal servis mesin: $e');
    }
  }
} // <--- KURUNG KURAWAL PENUTUP UTAMA ADA DI SINI