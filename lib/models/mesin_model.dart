class Mesin {
  final String id;
  final String nama;
  final String status;
  final DateTime terakhirMaintenance;

  Mesin({required this.id, required this.nama, required this.status, required this.terakhirMaintenance});

  // Fungsi untuk mengubah data dari Firebase menjadi Objek Mesin
  factory Mesin.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Mesin(
      id: documentId,
      nama: data['nama_mesin'] ?? '',
      status: data['status'] ?? 'Standby',
      terakhirMaintenance: data['terakhir_maintenance'].toDate(),
    );
  }
}