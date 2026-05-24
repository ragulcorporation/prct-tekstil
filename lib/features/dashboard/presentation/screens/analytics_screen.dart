import 'package:flutter/material.dart';
import 'package:k_tech/main.dart';

class AnalyticsScreen extends StatelessWidget {
  final double totalBerat;
  final int totalCacat;
  final Widget advancedAnalyticsSection;
  final Widget Function(String title, String val, IconData icon, Color col, bool isDark) buildSmallMetric;

  const AnalyticsScreen({
    super.key,
    required this.totalBerat,
    required this.totalCacat,
    required this.advancedAnalyticsSection,
    required this.buildSmallMetric,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            buildSmallMetric('TOTAL PRODUKSI', '${totalBerat.toStringAsFixed(1)} Kg', Icons.scale, Colors.blue, isDark),
            const SizedBox(width: 16),
            buildSmallMetric('TOTAL KAIN CACAT', '$totalCacat Roll', Icons.assignment_late, Colors.orange, isDark),
          ],
        ),
        const SizedBox(height: 20),
        advancedAnalyticsSection,

        // Taruh di dalam ListView(children: [ ... di bawah advancedAnalyticsSection ])
const SizedBox(height: 20),
Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: isDark ? const Color(0xFF1E293B) : Colors.white,
    borderRadius: BorderRadius.circular(24),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Efisiensi Target Produksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text('85% Achieved', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
      const SizedBox(height: 15),
      // Progress Bar Indikator Kain
      LinearProgressIndicator(
        value: totalBerat / 300.0, // Asumsi target harian 300 Kg
        backgroundColor: Colors.grey.withOpacity(0.2),
        color: const Color(0xFF1E3A8A),
        minHeight: 10,
        borderRadius: BorderRadius.circular(5),
      ),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Aktual: ${totalBerat.toStringAsFixed(1)} Kg', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const Text('Target Sektor: 300.0 Kg', style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      )
    ],
  ),
),
      ],
    );
  }
}