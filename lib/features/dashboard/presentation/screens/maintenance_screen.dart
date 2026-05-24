import 'package:flutter/material.dart';

class MaintenanceScreen extends StatelessWidget {
  final Widget maintenanceSection;

  const MaintenanceScreen({
    super.key,
    required this.maintenanceSection,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        maintenanceSection,

        // Taruh di dalam ListView(children: [ maintenanceSection, ... ])
const SizedBox(height: 20),
Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Theme.of(context).cardTheme.color,
    borderRadius: BorderRadius.circular(24),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange, size: 20),
          SizedBox(width: 8),
          Text('Informasi Kalibrasi Alat Instrumentasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
      const SizedBox(height: 12),
      Text(
        'Sesuai dengan regulasi mutu PT Kahatex, timbangan digital pada Jalur MSN-01 s/d MSN-03 wajib dikalibrasi ulang setiap 14 hari kerja guna menghindari penyimpangan deviasi berat roll kain.',
        style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
      ),
      const Divider(height: 25),
      const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Jadwal Kalibrasi Berikutnya:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          Text('05 Juni 2026', style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
        ],
      )
    ],
  ),
),
      ],
    );
  }
}