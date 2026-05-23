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

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  String selectedFilterMesin = 'Semua';
  String selectedTimeframe = 'Harian';
  late TabController _analyticsTabController;
  
  // State pengendali fase halaman di awal aplikasi
  bool _hasSelectedAccess = false; 

  @override
  void initState() {
    super.initState();
    _analyticsTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _analyticsTabController.dispose();
    super.dispose();
  }

  bool _perluMaintenance(DateTime tglServis) {
    final sekarang = DateTime.now();
    return sekarang.difference(tglServis).inDays >= 30; 
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // JIKA BELUM MEMILIH AKSES, TAMPILKAN HALAMAN WELCOME GATE (REQUEST UTAMA)
    if (!_hasSelectedAccess) {
      return _buildWelcomeGate(isDark);
    }

    // JIKA SUDAH, TAMPILKAN UTAMA DASHBOARD MES
    return _buildMainDashboard(isDark);
  }

  // ================= 1. GERBANG AWAL: WELCOME SCREEN =================
  Widget _buildWelcomeGate(bool isDark) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)] 
                : [const Color(0xFF0F172A), const Color(0xFF1E3A8A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(30)),
                child: const Icon(Icons.precision_manufacturing, color: Colors.blueAccent, size: 70),
              ),
              const SizedBox(height: 24),
              const Text('K-Tech Textile Panel', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Text('Manufacturing Execution System (MES)\nSimulasi Sektor Lantai Produksi PT Kahatex', 
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 48),
              
              // TOMBOL MASUK SEBAGAI OPERATOR (LOGIN)
              _buildWelcomeButton(
                label: 'LOGIN OPERATOR SHIFT',
                icon: Icons.lock_open,
                bgColor: Colors.blueAccent,
                textColor: Colors.white,
                onTap: () => _showLoginDialog(context),
              ),
              const SizedBox(height: 14),
              
              // TOMBOL REGISTRASI OPERATOR BARU
              _buildWelcomeButton(
                label: 'REGISTRASI OPERATOR BARU',
                icon: Icons.app_registration,
                bgColor: Colors.white.withOpacity(0.15),
                textColor: Colors.white,
                onTap: () => _showRegisterDialog(context),
              ),
              const SizedBox(height: 14),
              
              // TOMBOL MASUK SEBAGAI TAMU (READ-ONLY)
              _buildWelcomeButton(
                label: 'MASUK SEBAGAI TAMU (READ-ONLY)',
                icon: Icons.assignment_turned_in,
                bgColor: Colors.transparent,
                textColor: Colors.amberAccent,
                borderSide: const BorderSide(color: Colors.amberAccent, width: 1.5),
                onTap: () {
                  setState(() {
                    AppState.isLoggedIn = false;
                    AppState.currentWorker = "Tamu/Operator";
                    _hasSelectedAccess = true;
                  });
                },
              ),
              const SizedBox(height: 40),
              // Switch Tema di Welcome Screen
              IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: Colors.white70),
                onPressed: () {
                  MyApp.of(context)?.changeTheme(isDark ? ThemeMode.light : ThemeMode.dark);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeButton({
    required String label, 
    required IconData icon, 
    required Color bgColor, 
    required Color textColor, 
    BorderSide? borderSide,
    required VoidCallback onTap
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          side: borderSide,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
      ),
    );
  }

  // ================= 2. HALAMAN UTAMA: BENTO PANEL INTERAKTIF =================
  Widget _buildMainDashboard(bool isDark) {
    final theme = Theme.of(context);
    
    final filteredLogs = AppState.logProduksi.where((log) {
      if (selectedFilterMesin != 'Semua' && log['mesin_id'] != selectedFilterMesin) return false;
      return true;
    }).toList();

    double totalBerat = filteredLogs.fold(0.0, (sum, item) => sum + (item['berat'] as double));
    int totalCacat = filteredLogs.where((l) => l['status'] == 'Cacat').length;

    return Scaffold(
      body: Column(
        children: [
          // ================= INDUSTRIAL HEADER SECTION =================
          Container(
            padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 25),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark 
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] 
                    : [const Color(0xFF0F172A), const Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
              boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 12, offset: Offset(0, 3))],
            ),
            child: Column(
              children: [
            // ================= GANTI ROW UTAMA HEADER DENGAN KODE INI =================
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    // Judul dibungkus Expanded agar teks otomatis mengalah & mengecil jika layar sempit
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.precision_manufacturing, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              // PENTING: Tambahkan Flexible agar teks panjang tidak memaksa overflow
              Expanded(
                child: Text(
                  'K-Tech Textile Panel', 
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis, // Potong jadi ... jika mentok
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppState.isLoggedIn ? 'Fasilitas: PT Kahatex • Operator: ${AppState.currentWorker}' : 'Fasilitas: PT Kahatex • Mode Tamu', 
            style: const TextStyle(color: Colors.amberAccent, fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
    
    // Aksi sebelah kanan dibungkus Row biasa dengan ukuran ikon yang pas
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: Colors.white, size: 20), 
          onPressed: () => MyApp.of(context)?.changeTheme(isDark ? ThemeMode.light : ThemeMode.dark)
        ),
        // Gunakan InkWell/IconButton biasa daripada TextButton.icon yang memakan banyak ruang horizontal
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white, size: 20),
          tooltip: 'Keluar Gateway',
          onPressed: () => setState(() => _hasSelectedAccess = false),
        ),
      ],
    ),
  ],
),
                const SizedBox(height: 20),
                // Panel Dropdown Filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.12))),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, color: Colors.blueAccent, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<String>(
                          value: selectedFilterMesin,
                          dropdownColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                          isExpanded: true,
                          underline: const SizedBox(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          items: ['Semua', ...AppState.mesinList.map((m) => m['id'].toString())].map<DropdownMenuItem<String>>((String id) {
                            return DropdownMenuItem<String>(value: id, child: Text(id == 'Semua' ? 'Semua Mesin (Kahatex Area 1-3)' : 'Mesin ID: $id'));
                          }).toList(),
                          onChanged: (val) => setState(() => selectedFilterMesin = val!),
                        ),
                      ),
                      Container(width: 1, height: 24, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 12)),
                      Expanded(
                        child: DropdownButton<String>(
                          value: selectedTimeframe,
                          dropdownColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                          isExpanded: true,
                          underline: const SizedBox(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          items: ['Harian', 'Mingguan', 'Bulanan'].map<DropdownMenuItem<String>>((String t) {
                            return DropdownMenuItem<String>(value: t, child: Text('Timeline: $t'));
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

          // ================= SCROLLABLE BENTO BOX LAYER =================
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSmallMetric('TOTAL PRODUKSI BEAT', '${totalBerat.toStringAsFixed(1)} Kg', Icons.layers, const Color(0xFF1E3A8A), selectedTimeframe, isDark),
                    const SizedBox(width: 16),
                    _buildSmallMetric('TOTAL KAIN CACAT', '$totalCacat Roll', Icons.assignment_late, const Color(0xFFEA580C), 'Kualitas produksi', isDark),
                  ],
                ),
                const SizedBox(height: 20),
                
                _buildAdvancedAnalyticsSection(isDark),
                const SizedBox(height: 20),

                // Histori Pemantauan Lintasan Produksi
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Histori Pemantauan Log Lintasan Produksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                          Icon(Icons.history_toggle_off, color: Colors.grey[400], size: 20),
                        ],
                      ),
                      const SizedBox(height: 18),
                      filteredLogs.isEmpty
                        ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('Belum ada log kerja produksi di lintasan area ini.', style: TextStyle(color: Colors.grey, fontSize: 12))))
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredLogs.length,
                            separatorBuilder: (_, __) => Divider(height: 24, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                            itemBuilder: (context, index) {
                              final log = filteredLogs[index];
                              final isCacat = log['status'] == 'Cacat';
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: isCacat ? const Color(0xFFFEF2F2).withOpacity(0.1) : const Color(0xFFF0FDF4).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                  child: Icon(isCacat ? Icons.pattern : Icons.check_circle_outline, color: isCacat ? Colors.red : Colors.green, size: 22),
                                ),
                                title: Text(log['jenis_kain'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Color(0xFFE2E8F0) : const Color(0xFF1E293B))),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 6),
                                    Text('Mesin: ${log['mesin_id']} • ${log['shift']} • ${log['berat']} Kg', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : const Color(0xFF475569))),
                                    const SizedBox(height: 2),
                                    Text('Operator: ${log['operator']} • Jam: ${log['waktu']}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                  ],
                                ),
                                trailing: isCacat 
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: const Color(0xFFFEF2F2).withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.red.withOpacity(0.2))),
                                      child: Text(log['cacat'], style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: const Color(0xFFF0FDF4).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                      child: const Text('Normal Pass', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                              );
                            },
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                _buildMaintenanceSection(isDark),
                const SizedBox(height: 20),

                if (AppState.isLoggedIn)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        foregroundColor: isDark ? Colors.blueAccent : const Color(0xFF1E3A8A),
                        elevation: 0,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isDark ? Colors.blueAccent : const Color(0xFF1E3A8A), width: 1.5)),
                      ),
                      onPressed: () => _showAddMasterDialog(context),
                      icon: const Icon(Icons.add_box, size: 18),
                      label: const Text('REGISTRASI MESIN / KODE KAIN BARU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      
      floatingActionButton: AppState.isLoggedIn 
        ? Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.small(
                heroTag: 'fab_man_v3',
                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                child: Icon(Icons.note_add, color: isDark ? Colors.blueAccent : const Color(0xFF1E3A8A)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InputProduksiScreen())).then((_) => setState(() {})),
              ),
              const SizedBox(height: 14),
              FloatingActionButton.extended(
                heroTag: 'fab_qr_v3',
                backgroundColor: isDark ? Colors.blueAccent : const Color(0xFF1E3A8A),
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
                label: const Text('SCAN QRIS MESIN KAIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const QrScannerScreen())).then((_) => setState(() {})),
              ),
            ],
          )
        : null,
    );
  }

  // ================= ENGINE ANALYTICS MULTI-DIMENSI TERINTEGRASI =================
  Widget _buildAdvancedAnalyticsSection(bool isDark) {
    final theme = Theme.of(context);
    final currentLogs = AppState.logProduksi.where((log) {
      if (selectedFilterMesin != 'Semua' && log['mesin_id'] != selectedFilterMesin) return false;
      return true;
    }).toList();

    Map<String, double> produksiPerKain = {};
    for (var log in currentLogs) {
      String kain = log['jenis_kain'];
      double berat = log['berat'] as double;
      produksiPerKain[kain] = (produksiPerKain[kain] ?? 0.0) + berat;
    }

    Map<String, double> produksiPerShift = {'Shift 1': 0.0, 'Shift 2': 0.0, 'Shift 3': 0.0};
    for (var log in currentLogs) {
      String shift = log['shift'];
      double berat = log['berat'] as double;
      if (produksiPerShift.containsKey(shift)) {
        produksiPerShift[shift] = produksiPerShift[shift]! + berat;
      }
    }

    Map<String, Map<String, double>> shiftPerMesin = {'Shift 1': {}, 'Shift 2': {}, 'Shift 3': {}};
    for (var log in currentLogs) {
      String shift = log['shift'];
      String mId = log['mesin_id'];
      double berat = log['berat'] as double;
      if (shiftPerMesin.containsKey(shift)) {
        shiftPerMesin[shift]![mId] = (shiftPerMesin[shift]![mId] ?? 0.0) + berat;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Advanced Analytics Factory Visual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          const SizedBox(height: 12),
          TabBar(
            controller: _analyticsTabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: isDark ? Colors.blueAccent : const Color(0xFF1E3A8A),
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            indicatorColor: isDark ? Colors.blueAccent : const Color(0xFF1E3A8A),
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Produksi Per Kain'),
              Tab(text: 'Produksi Per Shift'),
              Tab(text: 'Detail Shift → Mesin'),
            ],
          ),
          SizedBox(
            height: 230,
            child: TabBarView(
              controller: _analyticsTabController,
              children: [
                // TAB 1: GRAFIK TOTAL PRODUKSI PER SERAT KAIN (SUDAH DIINTEGRASIKAN TOTAL DENGAN GRAFIK FL_CHART)
                Padding(
                  padding: const EdgeInsets.only(top: 30, right: 10, left: 10),
                  child: produksiPerKain.isEmpty
                      ? const Center(child: Text('Tidak ada log muatan kain pada mesin/filter ini.', style: TextStyle(color: Colors.grey, fontSize: 12)))
                      : BarChart(
                          BarChartData(
                            borderData: FlBorderData(show: false),
                            gridData: const FlGridData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    int idx = value.toInt();
                                    if (idx >= 0 && idx < produksiPerKain.keys.length) {
                                      String namaKain = produksiPerKain.keys.elementAt(idx);
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(namaKain, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : const Color(0xFF64748B))),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                            ),
                            barGroups: List.generate(produksiPerKain.length, (index) {
                              String key = produksiPerKain.keys.elementAt(index);
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: produksiPerKain[key] ?? 0.0,
                                    color: isDark ? Colors.blueAccent : const Color(0xFF1E3A8A),
                                    width: 24,
                                    borderRadius: BorderRadius.circular(6),
                                     
                                  )
                                ],
                                showingTooltipIndicators: [0],
                              );
                            }),
                            barTouchData: BarTouchData(
                              enabled: false,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (group) => Colors.transparent,
                                tooltipMargin: 4,
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  return BarTooltipItem(
                                    "${rod.toY.toStringAsFixed(1)} Kg",
                                    TextStyle(
                                      color: isDark ? Colors.white70 : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 10),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                ),

                // TAB 2: GRAFIK TOTAL PRODUKSI PER SHIFT GABUNGAN KAHATEX
                Padding(
                  padding: const EdgeInsets.only(top: 30, right: 10, left: 10),
                  child: BarChart(
                    BarChartData(
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final textStyle = TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : const Color(0xFF64748B));
                              if (value == 0) return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('Shift 1 (Pagi)', style: textStyle));
                              if (value == 1) return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('Shift 2 (Siang)', style: textStyle));
                              if (value == 2) return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('Shift 3 (Malam)', style: textStyle));
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: produksiPerShift['Shift 1']!, color: Colors.blue, width: 32, borderRadius: BorderRadius.circular(6),
                         )
                       ], showingTooltipIndicators: [0]),
                        BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: produksiPerShift['Shift 2']!, color: isDark ? Colors.blueAccent : const Color(0xFF1E3A8A), width: 32, borderRadius: BorderRadius.circular(6), )], showingTooltipIndicators: [0]),
                        BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: produksiPerShift['Shift 3']!, color: Colors.teal, width: 32, borderRadius: BorderRadius.circular(6),)], showingTooltipIndicators: [0]),
                      ],
                      barTouchData: BarTouchData(
                        enabled: false,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => Colors.transparent,
                          tooltipMargin: 6,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem("${rod.toY.toStringAsFixed(1)} Kg", TextStyle(color: isDark ? Colors.white70 : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 10));
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // TAB 3: DETAIL BREAKDOWN LINTASAN MESIN PER SHIFT
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ListView(
                    children: ['Shift 1', 'Shift 2', 'Shift 3'].map((sName) {
                      Map<String, double> mesinData = shiftPerMesin[sName]!;
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: isDark ? Colors.black87 : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(sName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: mesinData.isEmpty
                                    ? const Text('Belum ada pengerjaan roll', style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic))
                                    : Text(
                                        mesinData.entries.map((e) => "${e.key}: ${e.value.toStringAsFixed(1)} Kg").join("   |   "),
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.blueAccent : const Color(0xFF1E3A8A)),
                                        textAlign: TextAlign.end,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallMetric(String title, String val, IconData icon, Color col, String labelSub, bool isDark) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: col.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: col, size: 20),
                ),
                Text(labelSub, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey[400])),
              ],
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
            const SizedBox(height: 2),
            Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          ],
        ),
      ),
    );
  }

 Widget _buildMaintenanceSection(bool isDark) {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Theme.of(context).cardTheme.color, 
      borderRadius: BorderRadius.circular(24)
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ROW JUDUL KARTU YANG SUDAH DIPERBAIKI (ANTI OVERFLOW)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded( // <--- SUNTIKKAN EXPANDED DI SINI
              child: Text(
                'Preventive Maintenance Alert', // <--- Sederhanakan teks agar lebih aman di layar HP
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 14, 
                  color: isDark ? Colors.white : const Color(0xFF0F172A)
                ),
                overflow: TextOverflow.ellipsis, // <--- Potong dengan ... jika layar terlalu sempit
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.health_and_safety, color: Colors.green, size: 20),
          ],
        ),
        const SizedBox(height: 15),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: AppState.mesinList.length,
            separatorBuilder: (_, __) => Divider(height: 20, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
            itemBuilder: (context, index) {
              final mesin = AppState.mesinList[index];
              final isAlert = _perluMaintenance(mesin['terakhir_maintenance']);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: isAlert ? const Color(0xFFFFF7ED).withOpacity(0.1) : const Color(0xFFF0FDF4).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.settings_input_component, color: isAlert ? Colors.orange : Colors.green, size: 18),
                ),
                title: Text(mesin['nama'].toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                subtitle: Text('ID Lintasan: ${mesin['id']} • Status Kerja: ${mesin['status']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                trailing: isAlert 
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: const BoxDecoration(color: Color(0xFFEA580C), borderRadius: BorderRadius.all(Radius.circular(8))),
                      child: const Text('OVERDUE SERVIS!', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    )
                  : const Text('Kondisi Prima', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
              );
            },
          )
        ],
      ),
    );
  }

  // ================= DIALOG AUTH DI HALAMAN WELCOME GATES =================
  void _showRegisterDialog(BuildContext context) {
    TextEditingController userCtrl = TextEditingController();
    TextEditingController nameCtrl = TextEditingController();
    TextEditingController pinCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrasi ID Operator Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'ID Username')),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Lengkap Operator')),
            TextField(controller: pinCtrl, decoration: const InputDecoration(labelText: 'PIN Otoritas (4 Digit)'), keyboardType: TextInputType.number, obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (userCtrl.text.isNotEmpty && nameCtrl.text.isNotEmpty) {
                setState(() {
                  AppState.karyawanList.add({
                    'username': userCtrl.text.trim().toLowerCase(),
                    'nama': nameCtrl.text.trim(),
                    'pin': pinCtrl.text.trim()
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Operator Sukses Terdaftar! Silakan Login.'), backgroundColor: Colors.green));
              }
            }, 
            child: const Text('Registrasikan'),
          )
        ],
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    TextEditingController userCtrl = TextEditingController();
    TextEditingController pinCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sistem Verifikasi Operator'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'Username ID')),
            TextField(controller: pinCtrl, decoration: const InputDecoration(labelText: 'PIN Masuk'), keyboardType: TextInputType.number, obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final user = userCtrl.text.trim().toLowerCase();
              final pin = pinCtrl.text.trim();
              final ketemu = AppState.karyawanList.any((k) => k['username'] == user && k['pin'] == pin);
              if (ketemu) {
                final dataKaryawan = AppState.karyawanList.firstWhere((k) => k['username'] == user);
                setState(() {
                  AppState.isLoggedIn = true;
                  AppState.currentWorker = dataKaryawan['nama']!;
                  _hasSelectedAccess = true; // Langsung tembus masuk ke dashboard
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID Operator atau PIN salah!'), backgroundColor: Colors.red));
              }
            }, 
            child: const Text('Verifikasi Masuk'),
          )
        ],
      ),
    );
  }

  void _showAddMasterDialog(BuildContext context) {
    String type = 'Mesin';
    TextEditingController codeCtrl = TextEditingController(); 
    TextEditingController nameCtrl = TextEditingController();
    TextEditingController colorCtrl = TextEditingController(); 

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Registrasi Data Master Pabrik'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(label: const Text('Mesin Lintasan'), selected: type == 'Mesin', onSelected: (s) => setDialogState(() => type = 'Mesin')),
                  const SizedBox(width: 12),
                  ChoiceChip(label: const Text('Kode Kain Varian'), selected: type == 'Kain', onSelected: (s) => setDialogState(() => type = 'Kain')),
                ],
              ),
              const SizedBox(height: 15),
              if (type == 'Kain') ...[
                TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Kode Kain Mandiri (Misal: KHTX09)')),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Konstruksi Serat (Misal: Fleece)')),
                TextField(controller: colorCtrl, decoration: const InputDecoration(labelText: 'Varian Warna Benang (Misal: Green)')),
              ] else ...[
                TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'ID Jalur Mesin Baru (Misal: MSN-05)')),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Deskripsi Sektor Mesin')),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (type == 'Mesin') {
                    AppState.mesinList.add({'id': codeCtrl.text.toUpperCase(), 'nama': nameCtrl.text, 'status': 'Standby', 'terakhir_maintenance': DateTime.now()});
                  } else {
                    AppState.jenisKainList.add({
                      'kode': codeCtrl.text.toUpperCase().trim(),
                      'nama': nameCtrl.text.trim(),
                      'warna': colorCtrl.text.trim()
                    });
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('Registrasikan'),
            ),
          ],
        ),
      ),
    );
  }
}

// Extensi untuk menghindari eror linting warna dinamis pada text style
extension ColorDim on Colors {
  static const Color whiteDimmable = Color(0xFFE2E8F0);
  static const Color whiteEmmitive = Color(0xFFF1F5F9);
}