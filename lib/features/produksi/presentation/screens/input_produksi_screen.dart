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
  late String selectedKainGabungan; 
  String selectedShift = 'Shift 1';
  final TextEditingController _berat = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedMesin = widget.mesinIdFromQR ?? AppState.mesinList.first['id'].toString();
    final firstKain = AppState.jenisKainList.first;
    selectedKainGabungan = "${firstKain['kode']} - ${firstKain['warna']}";
  }

  @override
  void dispose() {
    _berat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pencatatan Hasil Kain')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: selectedShift,
                decoration: const InputDecoration(labelText: 'Shift Kerja'),
                items: ['Shift 1', 'Shift 2', 'Shift 3'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => selectedShift = v!),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: selectedMesin,
                decoration: const InputDecoration(labelText: 'Jalur Mesin'),
                items: AppState.mesinList.map<DropdownMenuItem<String>>((m) => DropdownMenuItem<String>(value: m['id'].toString(), child: Text(m['id'].toString()))).toList(),
                onChanged: (v) => setState(() => selectedMesin = v!),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: selectedKainGabungan,
                decoration: const InputDecoration(labelText: 'Spesifikasi Kain'),
                items: AppState.jenisKainList.map<DropdownMenuItem<String>>((k) => DropdownMenuItem<String>(value: "${k['kode']} - ${k['warna']}", child: Text("${k['kode']} - ${k['warna']}"))).toList(),
                onChanged: (v) => setState(() => selectedKainGabungan = v!),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _berat,
                decoration: const InputDecoration(labelText: 'Berat Roll (Kg)'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        AppState.logProduksi.insert(0, {
                          'tanggal': DateTime.now(),
                          'waktu': '12:00',
                          'shift': selectedShift,
                          'operator': AppState.currentWorker,
                          'mesin_id': selectedMesin,
                          'jenis_kain': selectedKainGabungan,
                          'berat': double.tryParse(_berat.text) ?? 0.0,
                          'status': 'Bagus',
                          'cacat': '',
                        });
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('SIMPAN LAPORAN'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}