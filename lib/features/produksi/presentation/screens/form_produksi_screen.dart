import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:k_tech/main.dart'; 

class FormProduksiScreen extends StatefulWidget {
  final String? scannedMesinId; // Menerima lemparan ID dari Scanner
  const FormProduksiScreen({super.key, this.scannedMesinId});

  @override
  State<FormProduksiScreen> createState() => _FormProduksiScreenState();
}

class _FormProduksiScreenState extends State<FormProduksiScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedMesin;
  String? _selectedKain;
  String _selectedShift = 'Shift 1';
  String _selectedStatus = 'Normal';
  final TextEditingController _beratController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _beratController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Ambil list kain dari AppState lokal (Master Kain)
    List<String> listKainDropdown = AppState.jenisKainList.isNotEmpty 
        ? AppState.jenisKainList.map((k) => "${k['kode']} - ${k['nama']}").toList()
        : ['EIGER11 - Katun Combed'];

    if (_selectedKain == null || !listKainDropdown.contains(_selectedKain)) {
      _selectedKain = listKainDropdown[0];
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E40AF),
        title: const Text('Form Pencatatan Produksi', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('mesin').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          List<String> listMesinDropdown = snapshot.hasData && snapshot.data!.docs.isNotEmpty
              ? snapshot.data!.docs.map((doc) => doc.id).toList()
              : ['MSN-01'];

          // Jika ada data lemparan dari Scanner, jadikan default
          if (_selectedMesin == null) {
            if (widget.scannedMesinId != null && listMesinDropdown.contains(widget.scannedMesinId)) {
              _selectedMesin = widget.scannedMesinId;
            } else {
              _selectedMesin = listMesinDropdown[0];
            }
          }

          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text('Input Hasil Kerja Lintasan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                  const SizedBox(height: 6),
                  const Text('Catat hasil produksi kain berdasarkan ID Mesin yang beroperasi.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4)),
                  const SizedBox(height: 28),

                  DropdownButtonFormField<String>(
                    value: _selectedMesin,
                    decoration: InputDecoration(
                      labelText: 'Pilih ID Mesin',
                      labelStyle: TextStyle(color: isDark ? Colors.blueAccent : const Color(0xFF1E40AF)),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.precision_manufacturing),
                    ),
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    items: listMesinDropdown.map((id) => DropdownMenuItem(value: id, child: Text('Mesin ID: $id', style: TextStyle(color: isDark ? Colors.white : Colors.black87)))).toList(),
                    onChanged: (val) => setState(() => _selectedMesin = val),
                  ),
                  const SizedBox(height: 18),

                  DropdownButtonFormField<String>(
                    value: _selectedKain,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Spesifikasi / Jenis Kain',
                      labelStyle: TextStyle(color: isDark ? Colors.blueAccent : const Color(0xFF1E40AF)),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.layers),
                    ),
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    items: listKainDropdown.map((fullKain) => DropdownMenuItem(value: fullKain, child: Text(fullKain, style: TextStyle(color: isDark ? Colors.white : Colors.black87), overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) => setState(() => _selectedKain = val),
                  ),
                  const SizedBox(height: 18),

                  DropdownButtonFormField<String>(
                    value: _selectedShift,
                    decoration: InputDecoration(
                      labelText: 'Shift Kerja',
                      labelStyle: TextStyle(color: isDark ? Colors.blueAccent : const Color(0xFF1E40AF)),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.schedule),
                    ),
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    items: ['Shift 1', 'Shift 2', 'Shift 3'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: TextStyle(color: isDark ? Colors.white : Colors.black87)))).toList(),
                    onChanged: (val) => setState(() => _selectedShift = val!),
                  ),
                  const SizedBox(height: 18),

                  TextFormField(
                    controller: _beratController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Berat Hasil Kain (Kg)',
                      labelStyle: TextStyle(color: isDark ? Colors.blueAccent : const Color(0xFF1E40AF)),
                      border: const OutlineInputBorder(),
                      hintText: '0.0',
                      prefixIcon: const Icon(Icons.scale),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Berat wajib diisi!';
                      if (double.tryParse(val) == null) return 'Masukkan angka desimal yang valid!';
                      if (double.parse(val) <= 0) return 'Berat harus > 0 Kg!';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Status Quality Control (QC)',
                      labelStyle: TextStyle(color: isDark ? Colors.blueAccent : const Color(0xFF1E40AF)),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.verified_user),
                    ),
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    items: ['Normal', 'Cacat'].map((st) => DropdownMenuItem(value: st, child: Text(st == 'Cacat' ? 'Cacat (Reject Roll)' : 'Normal (Passed OK)', style: TextStyle(color: isDark ? Colors.white : Colors.black87)))).toList(),
                    onChanged: (val) => setState(() => _selectedStatus = val!),
                  ),
                  const SizedBox(height: 36),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E40AF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.cloud_upload_outlined, size: 20),
                      label: Text(_isLoading ? 'MENYIMPAN...' : 'SIMPAN KE CLOUD LOG', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                      onPressed: _isLoading ? null : _simpanDataManual,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Future<void> _simpanDataManual() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final sekarang = DateTime.now();
    double beratInput = double.tryParse(_beratController.text) ?? 0.0;

    try {
      // Simpan langsung ke Server Firebase Firestore
      await FirebaseFirestore.instance.collection('log_produksi').add({
        'tanggal': Timestamp.fromDate(sekarang),
        'waktu': "${sekarang.hour.toString().padLeft(2, '0')}:${sekarang.minute.toString().padLeft(2, '0')}",
        'shift': _selectedShift,
        'operator': AppState.currentWorker,
        'mesin_id': _selectedMesin!,
        'jenis_kain': _selectedKain!,
        'berat': beratInput,
        'status': _selectedStatus,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, duration: Duration(seconds: 2), content: Text('SUKSES! Data berhasil diunggah ke Cloud Server.')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('Gagal menyimpan: $e')));
        setState(() => _isLoading = false);
      }
    }
  }
}