import 'package:flutter/material.dart';

class LogProduksiScreen extends StatelessWidget {
  final Widget logListSection;

  const LogProduksiScreen({
    super.key,
    required this.logListSection,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        logListSection,

        // Taruh di dalam ListView(children: [ logListSection, ... ])
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
      const Text('Ringkasan Pemeriksaan Kualitas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      const SizedBox(height: 15),
      Row(
        children: [
          Expanded(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading:  CircleAvatar(backgroundColor: Colors.green.withOpacity(0.1), 
              child: const Icon(Icons.check_circle, color: Colors.green)),
              title: const Text('Passed (QC OK)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              subtitle: const Text('2 Roll Kain', style: TextStyle(fontSize: 11)),
            ),
          ),
          Expanded(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: Colors.red.withOpacity(0.1), child: const Icon(Icons.cancel, color: Colors.red)),
              title: const Text('Rejected (Defect)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              subtitle: const Text('0 Roll Kain', style: TextStyle(fontSize: 11)),
            ),
          ),
        ],
      )
    ],
  ),
),
      ],
    );
  }
}