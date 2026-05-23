import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:k_tech/main.dart';
import 'package:k_tech/features/produksi/presentation/screens/input_produksi_screen.dart';
import 'package:k_tech/features/scanner/presentation/screens/qr_scanner_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String selectedFilterMesin = 'Semua';
  String selectedTimeframe = 'Harian';

  bool _perluMaintenance(DateTime tglServis) {
    final sekarang = DateTime.now();
    return sekarang.difference(tglServis).inDays >= 30; 
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    
    // Logika Filter Data
    final filteredLogs = AppState.logProduksi.where((log) {
      if (selectedFilterMesin != 'Semua' && log['mesin_id'] != selectedFilterMesin) return false;
      return true;
    }).toList();

    double totalBerat = filteredLogs.fold(0.0, (sum, item) => sum + (item['berat'] as double));
    int totalCacat = filteredLogs.where((l) => l['status'] == 'Cacat').length;

    return Scaffold(
      body: Column(
        children: [
          // ================= DARK HEADER SECTION =================
          Container(
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 30),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A), // Slate/Navy Super Gelap
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('K-Tech Textile Panel', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: () => setState(() => AppState.isLoggedIn = !AppState.isLoggedIn),
                      icon: Icon(AppState.isLoggedIn ? Icons.logout : Icons.login, color: Colors.white, size: 18),
                      label: Text(AppState.isLoggedIn ? 'Logout' : 'Login', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                // Filter Panel Kontras di Atas Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    children: [
                      const Icon(Icons.tune, color: Colors.white70, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButton<String>(
                          value: selectedFilterMesin,
                          dropdownColor: const Color(0xFF1E293B),
                          isExpanded: true,
                          underline: const SizedBox(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          items: ['Semua', ...AppState.mesinList.map((m) => m['id'].toString())].map<DropdownMenuItem<String>>((String id) {
                            return DropdownMenuItem<String>(
                              value: id,
                              child: Text(id == 'Semua' ? 'Semua Mesin' : 'Mesin $id'),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => selectedFilterMesin = val!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButton<String>(
                          value: selectedTimeframe,
                          dropdownColor: const Color(0xFF1E293B),
                          isExpanded: true,
                          underline: const SizedBox(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          items: ['Harian', 'Mingguan', 'Bulanan'].map<DropdownMenuItem<String>>((String t) {
                            return DropdownMenuItem<String>(value: t, child: Text(t));
                          }).toList(),
                          onChanged: (val) => setState(() => selectedTimeframe = val!),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ================= BENTO CONTENT LIST =================
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Bento Metrics Cards
                Row(
                  children: [
                    _buildSmallMetric('TOTAL PRODUKSI', '${totalBerat.toStringAsFixed(1)} Kg', Icons.scale, Colors.blue),
                    const SizedBox(width: 15),
                    _buildSmallMetric('TOTAL KAIN CACAT', '$totalCacat Roll', Icons.report_problem, Colors.orange),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Real-time Chart
                _buildChartSection(),
                const SizedBox(height: 20),

                // Alert Maintenance Mesin
                _buildMaintenanceSection(),
                const SizedBox(height: 20),

                // Tombol Tambah Master Data (Khusus Karyawan Logged-in)
                if (AppState.isLoggedIn) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1E40AF),
                      padding: const EdgeInsets.all(15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Color(0xFF1E40AF))),
                    ),
                    onPressed: () => _showAddMasterDialog(context),
                    icon: const Icon(Icons.settings_suggest),
                    label: const Text('TAMBAH MESIN / JENIS KAIN BARU', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 80), // Spacer tambahan di paling bawah biar gampang scroll
                ],
              ],
            ),
          ),
        ],
      ),
      
      // ================= OPSI INPUT GANDA FLOATING ACTION BUTTON =================
      floatingActionButton: AppState.isLoggedIn 
        ? Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.small(
                heroTag: 'btn_input_manual',
                backgroundColor: Colors.white,
                elevation: 4,
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InputProduksiScreen())).then((_) => setState(() {})),
                child: const Icon(Icons.edit_note, color: Color(0xFF1E40AF)),
              ),
              const SizedBox(height: 12),
              FloatingActionButton.extended(
                heroTag: 'btn_scan_qr',
                backgroundColor: const Color(0xFF1E40AF),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const QrScannerScreen())).then((_) => setState(() {})),
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                label: const Text('SCAN QRIS MESIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          )
        : null,
    );
  }

  // DIALOG TAMBAH MASTER DATA
  void _showAddMasterDialog(BuildContext context) {
    String type = 'Mesin';
    TextEditingController nameController = TextEditingController();
    TextEditingController idController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah Data Master Pabrik'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(label: const Text('Mesin'), selected: type == 'Mesin', onSelected: (s) => setDialogState(() => type = 'Mesin')),
                  const SizedBox(width: 12),
                  ChoiceChip(label: const Text('Jenis Kain'), selected: type == 'Kain', onSelected: (s) => setDialogState(() => type = 'Kain')),
                ],
              ),
              const SizedBox(height: 15),
              TextField(controller: nameController, decoration: InputDecoration(labelText: type == 'Mesin' ? 'Nama Mesin' : 'Nama Jenis Kain baru')),
              if (type == 'Mesin') TextField(controller: idController, decoration: const InputDecoration(labelText: 'ID Mesin Baru (Misal: MSN-04)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (type == 'Mesin') {
                    AppState.mesinList.add({'id': idController.text.toUpperCase(), 'nama': nameController.text, 'status': 'Standby', 'terakhir_maintenance': DateTime.now()});
                  } else {
                    AppState.jenisKainList.add(nameController.text);
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallMetric(String title, String val, IconData icon, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.withOpacity(0.08))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: col, size: 24),
            const SizedBox(height: 15),
            Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Produksi Per Shift ($selectedTimeframe)', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
          const SizedBox(height: 25),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 65, color: Colors.blue, width: 25, borderRadius: BorderRadius.circular(5))]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 110, color: const Color(0xFF1E40AF), width: 25, borderRadius: BorderRadius.circular(5))]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 35, color: Colors.teal, width: 25, borderRadius: BorderRadius.circular(5))]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Shift 1 (Pagi)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              Text('Shift 2 (Siang)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              Text('Shift 3 (Malam)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sistem Alert Maintenance Mesin (Siklus 1 Bulan)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
          const SizedBox(height: 15),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: AppState.mesinList.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final mesin = AppState.mesinList[index];
              final isAlert = _perluMaintenance(mesin['terakhir_maintenance']);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.precision_manufacturing, color: isAlert ? Colors.red : Colors.green),
                title: Text(mesin['nama'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('ID: ${mesin['id']} • Status: ${mesin['status']}', style: const TextStyle(fontSize: 11)),
                trailing: isAlert 
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: const BoxDecoration(color: Colors.red, borderRadius: BorderRadius.all(Radius.circular(6))),
                      child: const Text('BUTUH SERVIS!', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    )
                  : const Text('Aman', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
              );
            },
          )
        ],
      ),
    );
  }
}