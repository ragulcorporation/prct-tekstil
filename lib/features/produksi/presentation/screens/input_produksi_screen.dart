import 'package:flutter/material.dart';
import 'package:k_tech/main.dart';

class InputProduksiScreen extends StatefulWidget {
  final String? mesinIdFromQR;
  const InputProduksiScreen({super.key, this.mesinIdFromQR});

  @override
  State<InputProduksiScreen> createState() => _InputProduksiScreenState();
}

class _InputProduksiScreenState extends State<InputProduksiScreen> {
  final _formKey = GlobalKey<FormState>();
  late String selectedMesin;
  late String selectedKain;
  final TextEditingController _berat = TextEditingController();
  bool _isCacat = false;

  @override
  void initState() {
    super.initState();
    // Validasi pencegahan eror jika master mesin kosong atau QR bernilai aneh
    selectedMesin =
        widget.mesinIdFromQR ?? AppState.mesinList.first['id'].toString();
    selectedKain = AppState.jenisKainList.first;
  }

  @override
  void dispose() {
    _berat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Input Hasil Kain',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E40AF),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mesin yang Digunakan',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedMesin,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)))),
                items: AppState.mesinList.map<DropdownMenuItem<String>>((m) {
                  return DropdownMenuItem<String>(
                    value: m['id'].toString(),
                    child: Text("${m['id']} - ${m['nama']}"),
                  );
                }).toList(),
                onChanged: (v) => setState(() => selectedMesin = v!),
              ),
              const SizedBox(height: 20),
              const Text('Jenis Kain Produksi',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedKain,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)))),
                items:
                    AppState.jenisKainList.map<DropdownMenuItem<String>>((k) {
                  return DropdownMenuItem<String>(
                    value: k,
                    child: Text(k),
                  );
                }).toList(),
                onChanged: (v) => setState(() => selectedKain = v!),
              ),
              const SizedBox(height: 20),
              const Text('Berat Hasil Kain',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _berat,
                decoration: const InputDecoration(
                    labelText: 'Berat Kain (Kg)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)))),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                  title: const Text('Apakah Ada Cacat/Kerusakan pada Kain?',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  value: _isCacat,
                  onChanged: (v) => setState(() => _isCacat = v)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E40AF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        AppState.logProduksi.add({
                          'tanggal': DateTime.now(),
                          'waktu': '16:00',
                          'shift': 'Shift 2',
                          'mesin_id': selectedMesin,
                          'jenis_kain': selectedKain,
                          'berat': double.tryParse(_berat.text) ?? 0.0,
                          'status': _isCacat ? 'Cacat' : 'Bagus',
                          'cacat': _isCacat ? 'Terdeteksi Cacat Produksi' : '',
                        });
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('SIMPAN DATA KE PANEL',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
