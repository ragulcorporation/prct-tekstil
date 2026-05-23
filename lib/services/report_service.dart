import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // =====================================================================
  // 1. FUNGSI PENARIK DATA DARI FIREBASE (Berdasarkan Rentang Waktu)
  // =====================================================================
  Future<List<Map<String, dynamic>>> _tarikDataProduksi(DateTime mulai, DateTime akhir) async {
    try {
      final snapshot = await _db
          .collection('produksi_log')
          .where('timestamp', isGreaterThanOrEqualTo: mulai)
          .where('timestamp', isLessThanOrEqualTo: akhir)
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Gagal menarik data dari server: $e');
    }
  }

  // =====================================================================
  // 2. FUNGSI CETAK KE EXCEL (.xlsx)
  // =====================================================================
  Future<void> generateLaporanExcel({required DateTime mulai, required DateTime akhir}) async {
    try {
      final dataLaporan = await _tarikDataProduksi(mulai, akhir);
      
      // Inisialisasi file Excel
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Laporan Produksi'];
      excel.setDefaultSheet('Laporan Produksi');

      // Membuat Baris Header (Judul Kolom)
      List<String> header = ['Tanggal & Waktu', 'ID Mesin', 'Jenis Kain', 'Berat (Kg)', 'Status', 'Keterangan Cacat', 'Operator'];
      sheetObject.appendRow(header.map((e) => TextCellValue(e)).toList());

      // Memasukkan data dari Firestore baris demi baris
      for (var data in dataLaporan) {
        DateTime tgl = (data['timestamp'] as Timestamp).toDate();
        String formatTgl = "${tgl.day}/${tgl.month}/${tgl.year} ${tgl.hour}:${tgl.minute}";
        
        List<CellValue> row = [
          TextCellValue(formatTgl),
          TextCellValue(data['id_mesin'] ?? '-'),
          TextCellValue(data['jenis_kain'] ?? '-'),
          DoubleCellValue(data['berat'] ?? 0.0),
          TextCellValue(data['ada_cacat'] == true ? 'Cacat' : 'Bagus'),
          TextCellValue(data['detail_cacat'] ?? '-'),
          TextCellValue(data['operator'] ?? '-'),
        ];
        sheetObject.appendRow(row);
      }

      // Proses penyimpanan ke penyimpanan lokal HP lalu bagikan
      var fileBytes = excel.save();
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/Laporan_Produksi_KTech.xlsx';
      
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes!);

      // Munculkan menu pop-up untuk membagikan file (ke WA, Email, dll)
      await Share.shareXFiles([XFile(filePath)], text: 'Laporan Excel K-Tech Textile');
      
    } catch (e) {
      throw Exception('Gagal membuat Excel: $e');
    }
  }

  // =====================================================================
  // 3. FUNGSI CETAK KE PDF (.pdf)
  // =====================================================================
  Future<void> generateLaporanPDF({required DateTime mulai, required DateTime akhir}) async {
    try {
      final dataLaporan = await _tarikDataProduksi(mulai, akhir);
      final pdf = pw.Document();

      // Mengonversi data JSON Firestore menjadi List array agar bisa dibaca tabel PDF
      final tableData = dataLaporan.map((data) {
        DateTime tgl = (data['timestamp'] as Timestamp).toDate();
        return [
          "${tgl.day}/${tgl.month}/${tgl.year}",
          data['id_mesin']?.toString() ?? '-',
          data['jenis_kain']?.toString() ?? '-',
          "${data['berat']} Kg",
          data['ada_cacat'] == true ? 'Cacat' : 'Bagus',
        ];
      }).toList();

      // Menggambar halaman PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(level: 0, child: pw.Text('Laporan Produksi K-Tech Textile', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
              pw.Paragraph(text: 'Dicetak pada: ${DateTime.now().toString().split('.')[0]}'),
              pw.SizedBox(height: 20),
              
              // Widget Tabel PDF
              pw.TableHelper.fromTextArray(
                headers: ['Tanggal', 'Mesin', 'Kain', 'Berat', 'Status'],
                data: tableData,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
                cellAlignment: pw.Alignment.centerLeft,
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
              ),
            ];
          },
        ),
      );

      // Simpan dan Bagikan
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/Laporan_Produksi_KTech.pdf");
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([XFile(file.path)], text: 'Laporan PDF K-Tech Textile');

    } catch (e) {
      throw Exception('Gagal membuat PDF: $e');
    }
  }
}