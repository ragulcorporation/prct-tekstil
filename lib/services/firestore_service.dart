import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==========================================
  // 1. BAGIAN MESIN
  // ==========================================

  // Mengambil daftar mesin secara Real-Time (Cocok untuk StreamBuilder di Dashboard)
  Stream<List<Map<String, dynamic>>> streamMesin() {
    return _db.collection('mesin').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id, // ID Dokumen (Misal: MSN-01)
          'nama': data['nama_mesin'] ?? 'Mesin Tanpa Nama',
          'status': data['status'] ?? 'Standby',
          // Firebase menyimpan waktu dalam format Timestamp, kita ubah ke DateTime
          'terakhir_maintenance': (data['terakhir_maintenance'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    });
  }

  // Menambahkan Master Mesin Baru
  Future<void> tambahMesinBaru(String idMesin, String namaMesin) async {
    try {
      await _db.collection('mesin').doc(idMesin).set({
        'nama_mesin': namaMesin,
        'status': 'Standby',
        'terakhir_maintenance': FieldValue.serverTimestamp(), // Catat waktu saat ini dari server
      });
    } catch (e) {
      throw Exception('Gagal menambah mesin: $e');
    }
  }

  // ==========================================
  // 2. BAGIAN PRODUKSI LOG (INPUT KAIN)
  // ==========================================

  // Mengambil riwayat produksi hari ini secara Real-Time
  Stream<List<Map<String, dynamic>>> streamLogProduksiHariIni() {
    // Ambil waktu tengah malam hari ini sebagai batas awal
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

  // Menyimpan hasil input produksi kain (Modular, dipisah dari UI)
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
        'shift': 'Shift 1', // Nanti bisa dikembangkan untuk deteksi shift otomatis
        'id_mesin': idMesin,
        'jenis_kain': jenisKain,
        'berat': berat,
        'ada_cacat': adaCacat,
        'detail_cacat': detailCacat,
        'operator': 'Anonim', // Nanti diganti nama user yang sedang login
      });
    } catch (e) {
      throw Exception('Gagal menyimpan log produksi: $e');
    }
  }
}
// ==========================================
  // 3. BAGIAN MAINTENANCE & PERAWATAN MESIN
  // ==========================================

  // Fungsi 1: Menarik HANYA mesin yang butuh servis (Lebih dari 30 hari)
  Stream<List<Map<String, dynamic>>> streamAlarmMaintenance() {
    // Kita hitung mundur 30 hari dari detik ini
    final batasWaktu = DateTime.now().subtract(const Duration(days: 30));

    // Minta Firebase untuk HANYA mengirimkan mesin yang tanggal terakhir maintenance-nya
    // lebih lama (kurang dari) batas waktu 30 hari tersebut.
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

  // Fungsi 2: Mereset jadwal maintenance setelah teknisi selesai servis
  Future<void> resetJadwalMaintenance(String idMesin) async {
    try {
      await _db.collection('mesin').doc(idMesin).update({
        // Perbarui tanggal maintenance ke detik ini (waktu server)
        'terakhir_maintenance': FieldValue.serverTimestamp(),
        'status': 'Standby', // Kembalikan status mesin ke standby/siap produksi
      });
    } catch (e) {
      throw Exception('Gagal mereset jadwal servis mesin: $e');
    }
  }