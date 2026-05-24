import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:k_tech/main.dart';
import 'package:k_tech/features/dashboard/presentation/screens/analytics_screen.dart';
import 'package:k_tech/features/dashboard/presentation/screens/log_produksi_screen.dart';
import 'package:k_tech/features/dashboard/presentation/screens/maintenance_screen.dart';
import 'package:k_tech/features/dashboard/presentation/screens/input_management_screen.dart';
import 'package:k_tech/features/produksi/presentation/screens/input_produksi_screen.dart';
import 'package:k_tech/features/scanner/presentation/screens/qr_scanner_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  String selectedFilterMesin = 'Semua';
  int _currentBottomIndex = 0;
  bool _hasSelectedAccess = false;
  late TabController _analyticsTabController;

  @override
  void initState() {
    super.initState();
    _analyticsTabController = TabController(length: 2, vsync: this);

    // Auto-login check jika user sebelumnya sudah masuk
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      AppState.isLoggedIn = true;
      AppState.currentWorker =
          currentUser.email?.split('@').first.toUpperCase() ?? "Operator";
      _hasSelectedAccess = true;
    }
  }

  @override
  void dispose() {
    _analyticsTabController.dispose();
    super.dispose();
  }

  bool _perluMaintenance(dynamic tglData) {
    if (tglData == null) return false;
    DateTime tglServis =
        (tglData is Timestamp) ? tglData.toDate() : tglData as DateTime;
    final sekarang = DateTime.now();
    return sekarang.difference(tglServis).inDays >= 30;
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Data lini garmen Kahatex berhasil diperbarui!'),
            duration: Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    if (!_hasSelectedAccess) {
      return _buildWelcomeGate(isDark);
    }

    // ==================== REVOLUSI MULTI-STREAM BINDING FIREBASE ====================
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('mesin').snapshots(),
      builder: (context, snapshotMesin) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('log_produksi')
              .orderBy('tanggal', descending: true)
              .snapshots(),
          builder: (context, snapshotLog) {
            // Satukan data mesin dari Cloud ke AppState Lokal untuk sinkronisasi Dropdown
            if (snapshotMesin.hasData) {
              AppState.mesinList = snapshotMesin.data!.docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return {
                  'id': doc.id,
                  'nama': d['nama'] ?? d['nama_mesin'] ?? doc.id,
                  'status': d['status'] ?? 'Standby',
                  'terakhir_maintenance':
                      d['terakhir_maintenance'] ?? Timestamp.now(),
                };
              }).toList();
            }

            // Ambil data log produksi live dari Cloud
            List<Map<String, dynamic>> liveLogs = [];
            if (snapshotLog.hasData) {
              liveLogs = snapshotLog.data!.docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return {
                  'tanggal': d['tanggal'] ?? Timestamp.now(),
                  'waktu': d['waktu'] ?? '00:00',
                  'shift': d['shift'] ?? 'Shift 1',
                  'operator': d['operator'] ?? 'Unknown',
                  'mesin_id': d['mesin_id'] ?? 'MSN-01',
                  'jenis_kain': d['jenis_kain'] ?? 'EIGER11 - Red',
                  'berat': (d['berat'] as num?)?.toDouble() ?? 0.0,
                  'status': d['status'] ?? 'Bagus',
                };
              }).toList();
            }

            // Filter data berdasarkan Dropdown mesin aktif
            final filteredLogs = liveLogs.where((log) {
              return selectedFilterMesin == 'Semua' ||
                  log['mesin_id'] == selectedFilterMesin;
            }).toList();

            double totalBerat = filteredLogs.fold(
                0.0, (sum, item) => sum + (item['berat'] as double));
            int totalCacat = filteredLogs
                .where((l) => l['status'].toString().toLowerCase() == 'cacat')
                .length;

            Widget currentScreenBody;
            switch (_currentBottomIndex) {
              case 0:
                currentScreenBody = RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: const Color(0xFF1E3A8A),
                  child: AnalyticsScreen(
                      totalBerat: totalBerat,
                      totalCacat: totalCacat,
                      advancedAnalyticsSection:
                          _buildAdvancedAnalyticsSection(isDark, filteredLogs),
                      buildSmallMetric: _buildSmallMetric),
                );
                break;
              case 1:
                currentScreenBody = LogProduksiScreen(
                    logListSection:
                        _buildLogListSection(filteredLogs, isDark, theme));
                break;
              case 3:
                currentScreenBody = AppState.isLoggedIn
                    ? InputManagementScreen(
                        onAddMasterTap: () => _showAddMasterDialog(context))
                    : const Center(
                        child: Text(
                            'Akses Ditolak: Anda harus login sebagai Operator.'));
                break;
              case 4:
                currentScreenBody = MaintenanceScreen(
                    maintenanceSection: _buildMaintenanceSection(isDark));
                break;
              case 2:
                if (!AppState.isLoggedIn) {
                  currentScreenBody = MaintenanceScreen(
                      maintenanceSection: _buildMaintenanceSection(isDark));
                } else {
                  currentScreenBody =
                      const Center(child: CircularProgressIndicator());
                }
                break;
              default:
                currentScreenBody =
                    const Center(child: Text('Halaman Tidak Ditemukan'));
            }

            return Scaffold(
              backgroundColor:
                  isDark ? const Color(0xFF0F172A) : const Color(0xFFEDF2F7),
              body: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.only(
                        top: 50, left: 24, right: 24, bottom: 25),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0xFF1E293B),
                                  const Color(0xFF0F172A)
                                ]
                              : [
                                  const Color(0xFF1E3A8A),
                                  const Color(0xFF0F172A)
                                ],
                        ),
                        borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ]),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.texture,
                                          color: Colors.blueAccent, size: 20),
                                      SizedBox(width: 8),
                                      Text('K-Tech Textile Panel',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    AppState.isLoggedIn
                                        ? 'Fasilitas: PT Kahatex • Operator: ${AppState.currentWorker}'
                                        : 'Fasilitas: PT Kahatex • Mode Tamu (Read-Only)',
                                    style: TextStyle(
                                        color: AppState.isLoggedIn
                                            ? const Color(0xFF34D399)
                                            : const Color(0xFFFBBF24),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.refresh_rounded,
                                      color: Colors.white70, size: 20),
                                  onPressed: _handleRefresh,
                                ),
                                IconButton(
                                    icon: Icon(
                                        isDark
                                            ? Icons.light_mode_outlined
                                            : Icons.dark_mode_outlined,
                                        color: Colors.white70,
                                        size: 20),
                                    onPressed: () => MyApp.of(context)
                                        ?.changeTheme(isDark
                                            ? ThemeMode.light
                                            : ThemeMode.dark)),
                                IconButton(
                                    icon: const Icon(Icons.logout_rounded,
                                        color: Colors.white70, size: 18),
                                    onPressed: () async {
                                      await FirebaseAuth.instance.signOut();
                                      setState(() {
                                        AppState.isLoggedIn = false;
                                        _hasSelectedAccess = false;
                                        _currentBottomIndex = 0;
                                      });
                                    }),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : const Color(0xFF334155).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black12)),
                          child: Row(
                            children: [
                              Icon(Icons.tune_rounded,
                                  color: isDark
                                      ? Colors.blueAccent
                                      : const Color(0xFF1E3A8A),
                                  size: 16),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButton<String>(
                                  value: selectedFilterMesin,
                                  dropdownColor: isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFFFFFFF),
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                  items: [
                                    'Semua',
                                    ...AppState.mesinList
                                        .map((m) => m['id'].toString())
                                  ].map((id) {
                                    return DropdownMenuItem(
                                        value: id,
                                        child: Text(id == 'Semua'
                                            ? 'Semua Jalur Lini (Sektor 1-3 Kahatex)'
                                            : 'Jalur Lintasan Mesin: $id'));
                                  }).toList(),
                                  onChanged: (val) => setState(
                                      () => selectedFilterMesin = val!),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: currentScreenBody),
                ],
              ),
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(
                            color: isDark ? Colors.white10 : Colors.black12,
                            width: 1))),
                child: BottomNavigationBar(
                  currentIndex: _currentBottomIndex,
                  onTap: (index) {
                    if (AppState.isLoggedIn && index == 2) {
                      Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const QrScannerScreen()))
                          .then((_) => setState(() {}));
                      return;
                    }
                    setState(() => _currentBottomIndex = index);
                  },
                  selectedItemColor:
                      isDark ? Colors.blueAccent : const Color(0xFF1E3A8A),
                  unselectedItemColor: const Color(0xFF94A3B8),
                  showUnselectedLabels: true,
                  type: BottomNavigationBarType.fixed,
                  backgroundColor:
                      isDark ? const Color(0xFF0F172A) : Colors.white,
                  items: AppState.isLoggedIn
                      ? [
                          const BottomNavigationBarItem(
                              icon: Icon(Icons.analytics_outlined, size: 22),
                              label: 'Analytics'),
                          const BottomNavigationBarItem(
                              icon: Icon(Icons.receipt_long_rounded, size: 22),
                              label: 'Log Kain'),
                          const BottomNavigationBarItem(
                            icon: CircleAvatar(
                                radius: 16,
                                backgroundColor: Color(0xFF1E3A8A),
                                child: Icon(Icons.qr_code_scanner_rounded,
                                    color: Colors.white, size: 16)),
                            label: 'Scan',
                          ),
                          const BottomNavigationBarItem(
                              icon: Icon(Icons.note_add_outlined, size: 22),
                              label: 'Input Data'),
                          const BottomNavigationBarItem(
                              icon: Icon(Icons.build_circle_outlined, size: 22),
                              label: 'Maint.'),
                        ]
                      : [
                          const BottomNavigationBarItem(
                              icon: Icon(Icons.analytics_outlined, size: 22),
                              label: 'Analytics'),
                          const BottomNavigationBarItem(
                              icon: Icon(Icons.receipt_long_rounded, size: 22),
                              label: 'Log Kain'),
                          const BottomNavigationBarItem(
                              icon: Icon(Icons.build_circle_outlined, size: 22),
                              label: 'Maint.'),
                        ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWelcomeGate(bool isDark) {
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          ClipPath(
            clipper: WelcomeHeaderClipper(),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.40,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.15))),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              )),
                          const SizedBox(width: 8),
                          const Text('SYSTEM STATUS: SERVER CLOUD ONLINE',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A).withOpacity(0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF3B82F6).withOpacity(0.2),
                              width: 1.5)),
                      child: const Icon(Icons.hub_outlined,
                          color: Color(0xFF60A5FA), size: 36),
                    ),
                    const SizedBox(height: 20),
                    Text('K-Tech Textile Panel',
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                        'Manufacturing Execution System (MES)\nSimulasi Sektor Produksi Terintegrasi Firebase',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                            height: 1.4,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 4))
                          ]),
                      child: Column(
                        children: [
                          _buildWelcomeButton(
                              'LOGIN OPERATOR CLOUD',
                              Icons.lock_open_rounded,
                              const Color(0xFF1E3A8A),
                              Colors.white,
                              () => _showLoginDialog(context)),
                          const SizedBox(height: 12),
                          _buildWelcomeButton(
                              'REGISTRASI ANGGOTA BARU',
                              Icons.person_add_alt_1_outlined,
                              isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFF1F5F9),
                              isDark ? Colors.white70 : Colors.black87,
                              () => _showRegisterDialog(context)),
                          const SizedBox(height: 12),
                          const Row(
                            children: [
                              Expanded(
                                  child: Divider(
                                      color: Colors.black12,
                                      endIndent: 8,
                                      indent: 8)),
                              Text('Atau',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey)),
                              Expanded(
                                  child: Divider(
                                      color: Colors.black12,
                                      endIndent: 8,
                                      indent: 8)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildWelcomeButton(
                              'MASUK SEBAGAI TAMU (READ-ONLY)',
                              Icons.assignment_ind_outlined,
                              Colors.transparent,
                              const Color(0xFF64748B), () {
                            setState(() {
                              AppState.isLoggedIn = false;
                              AppState.currentWorker = "Tamu/Operator";
                              _hasSelectedAccess = true;
                              _currentBottomIndex = 0;
                            });
                          },
                              borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF475569)
                                      : const Color(0xFFCBD5E1),
                                  width: 1.2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeButton(String label, IconData icon, Color bgColor,
      Color textColor, VoidCallback onTap,
      {BorderSide? borderSide}) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: textColor,
            side: borderSide,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0),
        onPressed: onTap,
        icon: Icon(icon, size: 14),
        label: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.3)),
      ),
    );
  }

  Widget _buildAdvancedAnalyticsSection(
      bool isDark, List<Map<String, dynamic>> currentLogs) {
    Map<String, double> produksiPerKain = {};
    double maxKainValue = 10.0;
    for (var log in currentLogs) {
      double berat = log['berat'] as double;
      produksiPerKain[log['jenis_kain']] =
          (produksiPerKain[log['jenis_kain']] ?? 0.0) + berat;
      if (produksiPerKain[log['jenis_kain']]! > maxKainValue) {
        maxKainValue = produksiPerKain[log['jenis_kain']]!;
      }
    }

    Map<String, double> produksiPerShift = {
      'Shift 1': 0.0,
      'Shift 2': 0.0,
      'Shift 3': 0.0
    };
    double maxShiftValue = 10.0;
    for (var log in currentLogs) {
      if (produksiPerShift.containsKey(log['shift'])) {
        produksiPerShift[log['shift']] = math.max(
            0.0, produksiPerShift[log['shift']]! + (log['berat'] as double));
        if (produksiPerShift[log['shift']]! > maxShiftValue) {
          maxShiftValue = produksiPerShift[log['shift']]!;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _analyticsTabController,
            labelColor: isDark ? Colors.blueAccent : const Color(0xFF1E3A8A),
            unselectedLabelColor: Colors.grey,
            indicatorColor:
                isDark ? Colors.blueAccent : const Color(0xFF1E3A8A),
            tabs: const [Tab(text: 'Per Kain'), Tab(text: 'Per Shift Lini')],
          ),
          SizedBox(
            height: 220,
            child: TabBarView(
              controller: _analyticsTabController,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 35, left: 5, right: 10),
                  child: produksiPerKain.isEmpty
                      ? const Center(
                          child: Text('Belum ada data log masuk.',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.grey)))
                      : BarChart(
                          BarChartData(
                            maxY: maxKainValue * 1.25,
                            borderData: FlBorderData(show: false),
                            gridData:
                                FlGridData(show: true, drawVerticalLine: false),
                            titlesData: FlTitlesData(
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    int idx = value.toInt();
                                    if (idx >= 0 &&
                                        idx < produksiPerKain.keys.length) {
                                      return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                              produksiPerKain.keys
                                                  .elementAt(idx)
                                                  .split(' - ')
                                                  .first,
                                              style: const TextStyle(
                                                  fontSize: 9,
                                                  fontWeight:
                                                      FontWeight.bold)));
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                            ),
                            barGroups:
                                List.generate(produksiPerKain.length, (index) {
                              String key =
                                  produksiPerKain.keys.elementAt(index);
                              return BarChartGroupData(x: index, barRods: [
                                BarChartRodData(
                                    toY: produksiPerKain[key]!,
                                    color: isDark
                                        ? Colors.blueAccent
                                        : const Color(0xFF1E3A8A),
                                    width: 16,
                                    borderRadius: BorderRadius.circular(4))
                              ], showingTooltipIndicators: [
                                0
                              ]);
                            }),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 35, left: 5, right: 10),
                  child: BarChart(
                    BarChartData(
                      maxY: maxShiftValue * 1.25,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value == 0)
                                return const Padding(
                                    padding: EdgeInsets.only(top: 8.0),
                                    child: Text('S1',
                                        style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold)));
                              if (value == 1)
                                return const Padding(
                                    padding: EdgeInsets.only(top: 8.0),
                                    child: Text('S2',
                                        style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold)));
                              if (value == 2)
                                return const Padding(
                                    padding: EdgeInsets.only(top: 8.0),
                                    child: Text('S3',
                                        style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold)));
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        BarChartGroupData(x: 0, barRods: [
                          BarChartRodData(
                              toY: produksiPerShift['Shift 1']!,
                              color: Colors.blueAccent,
                              width: 18,
                              borderRadius: BorderRadius.circular(4))
                        ], showingTooltipIndicators: [
                          0
                        ]),
                        BarChartGroupData(x: 1, barRods: [
                          BarChartRodData(
                              toY: produksiPerShift['Shift 2']!,
                              color: const Color(0xFF1E3A8A),
                              width: 18,
                              borderRadius: BorderRadius.circular(4))
                        ], showingTooltipIndicators: [
                          0
                        ]),
                        BarChartGroupData(x: 2, barRods: [
                          BarChartRodData(
                              toY: produksiPerShift['Shift 3']!,
                              color: Colors.teal,
                              width: 18,
                              borderRadius: BorderRadius.circular(4))
                        ], showingTooltipIndicators: [
                          0
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogListSection(
      List<Map<String, dynamic>> logs, bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Log Hasil Kain (Firestore Cloud)',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87)),
              IconButton(
                icon: const Icon(Icons.analytics_rounded,
                    color: Colors.green, size: 20),
                onPressed: () => _exportToSpreadsheet(context, logs),
              ),
            ],
          ),
          const SizedBox(height: 10),
          logs.isEmpty
              ? const Center(
                  child: Text('Tidak ada lembaran kain terdata di cloud',
                      style: TextStyle(fontSize: 11, color: Colors.grey)))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length > 5
                      ? 5
                      : logs.length, // Tampilkan maksimal 5 baris di dashboard
                  itemBuilder: (context, index) {
                    final item = logs[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.grain,
                          color: isDark ? Colors.white30 : Colors.blueGrey,
                          size: 16),
                      title: Text(item['jenis_kain'],
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFE2E8F0)
                                  : Colors.black87)),
                      subtitle: Text(
                          'Mesin: ${item['mesin_id']} • Op: ${item['operator']}',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey)),
                      trailing: Text('${item['berat']} Kg',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF1E3A8A))),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildSmallMetric(
      String title, String val, IconData icon, Color col, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: col, size: 18),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 9,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold)),
            Text(val,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Text('Kondisi Fisik & Kalibrasi Sektor',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black87))),
              const Icon(Icons.grid_3x3_rounded, color: Colors.teal, size: 18),
            ],
          ),
          const SizedBox(height: 15),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: AppState.mesinList.length,
            separatorBuilder: (_, __) => const Divider(height: 20),
            itemBuilder: (context, index) {
              final mesin = AppState.mesinList[index];
              final isAlert = _perluMaintenance(mesin['terakhir_maintenance']);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.construction,
                    color: isAlert ? Colors.amber : Colors.green, size: 18),
                title: Text(mesin['nama'].toString(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12)),
                subtitle: Text(
                    'ID Lintasan: ${mesin['id']} • Status: ${mesin['status']}',
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF64748B))),
                trailing: isAlert
                    ? const Text('BUTUH SERVIS!',
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 9,
                            fontWeight: FontWeight.bold))
                    : const Text('Prima',
                        style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 10)),
              );
            },
          )
        ],
      ),
    );
  }

  Future<void> _exportToSpreadsheet(
      BuildContext context, List<Map<String, dynamic>> logs) async {
    if (logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal Export: Data log masih kosong!'),
          backgroundColor: Colors.red));
      return;
    }

    // 1. Tampilkan indikator loading (opsional)
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sedang membuat file Spreadsheet...'),
        duration: Duration(seconds: 1)));

    try {
      // 2. Susun data menjadi format CSV (Bisa dibuka di Excel)
      String csvContent =
          "Tanggal,Waktu,Shift,Operator,ID Mesin,Spesifikasi Kain,Berat (Kg),Status\n";
      for (var log in logs) {
        String tanggal = log['tanggal'].toString().split(' ').first;
        String waktu = log['waktu']?.toString() ?? '12:00';
        String shift = log['shift']?.toString() ?? '-';
        String operator = log['operator']?.toString() ?? '-';
        String mesinId = log['mesin_id']?.toString() ?? '-';
        String jenisKain = log['jenis_kain']?.toString() ?? '-';
        String berat = log['berat']?.toString() ?? '0';
        String status = log['status']?.toString() ?? '-';

        csvContent +=
            "$tanggal,$waktu,$shift,$operator,$mesinId,$jenisKain,$berat,$status\n";
      }

      // 3. Dapatkan folder penyimpanan sementara di HP Android
      final directory = await getTemporaryDirectory();

      // 4. Buat file fisik bernama "Laporan_Produksi_Kahatex.csv"
      final path = "${directory.path}/Laporan_Produksi_Kahatex.csv";
      final file = File(path);

      // 5. Tulis data ke dalam file fisik tersebut
      await file.writeAsString(csvContent);

      // 6. Munculkan menu "Share/Simpan" bawaan HP
      if (context.mounted) {
        // Menggunakan XFile untuk share_plus versi terbaru
        await Share.shareXFiles([XFile(path)],
            text: 'Berikut adalah lampiran file Laporan Produksi K-Tech MES.');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal membuat file: $e'),
            backgroundColor: Colors.red));
      }
    }
  }

  // ==================== REFAKTOR AUTHENTICATION LOGIN DIALOG ====================
  void _showLoginDialog(BuildContext context) {
    TextEditingController emailCtrl = TextEditingController();
    TextEditingController passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Otorisasi Operator (Firebase Auth)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email Operator')),
            TextField(
                controller: passCtrl,
                decoration: const InputDecoration(
                    labelText: 'Password (Min 6 Karakter)'),
                obscureText: true)
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              try {
                UserCredential cred =
                    await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: emailCtrl.text.trim().toLowerCase(),
                  password: passCtrl.text.trim(),
                );
                setState(() {
                  AppState.isLoggedIn = true;
                  AppState.currentWorker =
                      cred.user?.email?.split('@').first.toUpperCase() ??
                          "Operator";
                  _hasSelectedAccess = true;
                  _currentBottomIndex = 0;
                });
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Gagal Login: $e'),
                      backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('Confirm'),
          )
        ],
      ),
    );
  }

  // ==================== REFAKTOR AUTHENTICATION REGISTER DIALOG ====================
  void _showRegisterDialog(BuildContext context) {
    TextEditingController emailCtrl = TextEditingController();
    TextEditingController passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrasi Akun Sektor Baru',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email Baru')),
            TextField(
                controller: passCtrl,
                decoration: const InputDecoration(
                    labelText: 'Password Baru (Min 6 Karakter)'),
                obscureText: true)
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.createUserWithEmailAndPassword(
                  email: emailCtrl.text.trim().toLowerCase(),
                  password: passCtrl.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Registrasi sukses! Silakan login.'),
                      backgroundColor: Colors.green));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Gagal: $e'), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('Daftar'),
          )
        ],
      ),
    );
  }

  // ==================== INTEGRASI DIALOG REGISTRASI MESIN KE FIRESTORE ====================
  void _showAddMasterDialog(BuildContext context) {
    String type = 'Mesin';
    TextEditingController codeCtrl = TextEditingController();
    TextEditingController nameCtrl = TextEditingController();
    TextEditingController colorCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Registrasi Data Master Kain/Alat',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8.0,
                children: [
                  ChoiceChip(
                      label: const Text('Master Alat'),
                      selected: type == 'Mesin',
                      onSelected: (s) => setDialogState(() => type = 'Mesin')),
                  ChoiceChip(
                      label: const Text('Konstruksi Kain'),
                      selected: type == 'Kain',
                      onSelected: (s) => setDialogState(() => type = 'Kain'))
                ],
              ),
              const SizedBox(height: 15),
              if (type == 'Kain') ...[
                TextField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(labelText: 'Kode Kain')),
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Serat')),
                TextField(
                    controller: colorCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Varian Warna'))
              ] else ...[
                TextField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(
                        labelText: 'ID Jalur Mesin Baru (Misal: MSN-04)')),
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Deskripsi Sektor Mesin'))
              ]
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final code = codeCtrl.text.toUpperCase().trim();
                final name = nameCtrl.text.trim();
                if (code.isEmpty || name.isEmpty) return;

                if (type == 'Mesin') {
                  try {
                    // Upload langsung ke cloud server Firestore
                    await FirebaseFirestore.instance
                        .collection('mesin')
                        .doc(code)
                        .set({
                      'nama_mesin': name,
                      'status': 'Standby',
                      'terakhir_maintenance': Timestamp.now(),
                    });
                  } catch (e) {
                    if (context.mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal upload: $e')));
                  }
                } else {
                  // Tambah Kain (Local Master)
                  setState(() {
                    AppState.jenisKainList.add({
                      'kode': code,
                      'nama': name,
                      'warna': colorCtrl.text.trim()
                    });
                  });
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Simpan Master'),
            )
          ],
        ),
      ),
    );
  }
}

class WelcomeHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);
    var firstControlPoint = Offset(size.width / 2, size.height);
    var firstEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
