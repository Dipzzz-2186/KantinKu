import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kantinku/models/order_model.dart';
import 'package:kantinku/models/order_item_model.dart';
import 'package:kantinku/models/product_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:universal_html/html.dart' as html;

class ExcelExportUtils {
  // --- BAGIAN 1: FUNGSI PEMBUATAN FILE EXCEL ---

  // Mengembalikan byte Laporan Harian
  static Future<List<int>?> exportDailyReport({
    required List<Order> orders,
    required List<OrderItem> items,
    required List<Product> products,
    required String staffName,
  }) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add( Duration(days: 1)).subtract( Duration(microseconds: 1));
    return _generateExcelBytes(
      orders: orders,
      items: items,
      products: products,
      reportTitle: 'Rekap Harian (Completed) - ${DateFormat('dd MMMM yyyy').format(now)}',
      dateRange: DateTimeRange(start: startOfDay, end: endOfDay),
    );
  }

  // Mengembalikan byte Laporan Mingguan
  static Future<List<int>?> exportWeeklyReport({
    required List<Order> orders,
    required List<OrderItem> items,
    required List<Product> products,
    required String staffName,
  }) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add( Duration(days: 6));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final end = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day).add( Duration(days: 1)).subtract( Duration(microseconds: 1));
    return _generateExcelBytes(
      orders: orders,
      items: items,
      products: products,
      reportTitle: 'Rekap Mingguan (Completed) - ${DateFormat('dd MMM').format(start)} s/d ${DateFormat('dd MMM yyyy').format(end)}',
      dateRange: DateTimeRange(start: start, end: end),
    );
  }

  // Mengembalikan byte Laporan Total
  static Future<List<int>?> exportTotalReport({
    required List<Order> orders,
    required List<OrderItem> items,
    required List<Product> products,
    required String staffName,
  }) {
    return _generateExcelBytes(
      orders: orders,
      items: items,
      products: products,
      reportTitle: 'Rekap Total Penjualan (Completed) - $staffName',
      dateRange: null,
    );
  }

  // Fungsi inti privat yang HANYA membuat Excel dan mengembalikan bytes
  static Future<List<int>?> _generateExcelBytes({
    required List<Order> orders,
    required List<OrderItem> items,
    required List<Product> products,
    required DateTimeRange? dateRange,
    required String reportTitle,
  }) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Rekap Penjualan'];

    // Filter data... (logika ini tetap sama)
    final staffProductIds = products.map((p) => p.id).toSet();
    final Map<int, Product> productMap = {for (var p in products) p.id: p};
    final filteredOrders = dateRange == null ? orders : orders.where((order) {
      if (order.tanggalPesanan == null) return false;
      final orderDate = DateTime.parse(order.tanggalPesanan!);
      return orderDate.isAfter(dateRange.start) && orderDate.isBefore(dateRange.end);
    }).toList();
    final filteredOrderIds = filteredOrders.map((o) => o.id).toSet();
    final staffCompletedItems = items.where((item) => staffProductIds.contains(item.productId) && item.status.toLowerCase() == 'completed' && filteredOrderIds.contains(item.orderId)).toList();
    filteredOrders.sort((a, b) => DateTime.parse(b.tanggalPesanan!).compareTo(DateTime.parse(a.tanggalPesanan!)));
    final double totalRevenue = staffCompletedItems.fold(0.0, (sum, item) => sum + item.subtotal);

    // Styling... (logika ini tetap sama)
    final CellStyle headerStyle = CellStyle(bold: true, horizontalAlign: HorizontalAlign.Center, verticalAlign: VerticalAlign.Center)..backgroundColor = ExcelColor.fromHexString('#FF6D4C41')..fontColor = ExcelColor.fromHexString('#FFFFFFFF');
    final CellStyle totalStyle = CellStyle(bold: true)..backgroundColor = ExcelColor.fromHexString('#FFF9E6');
    final CellStyle currencyStyle = CellStyle(numberFormat: NumFormat.custom(formatCode: r'Rp #,##0'));

    // Tulis data ke sheet... (logika ini tetap sama)
    sheet.appendRow([TextCellValue(reportTitle)]);
    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('G1'));
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = headerStyle;
    sheet.appendRow([]);
    final List<String> tableHeaders = ['ID Pesanan', 'Tanggal', 'Nama Produk', 'Jumlah', 'Harga Satuan', 'Subtotal', 'Status Item'];
    sheet.appendRow(tableHeaders.map((h) => TextCellValue(h)).toList());
    for (var i = 0; i < tableHeaders.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: sheet.maxRows - 1)).cellStyle = headerStyle;
    }
    for (final order in filteredOrders) {
      var itemsForThisOrder = staffCompletedItems.where((item) => item.orderId == order.id).toList();
      if (itemsForThisOrder.isEmpty) continue;
      final Map<int, OrderItem> aggregatedItems = {};
      for (final item in itemsForThisOrder) {
        if (aggregatedItems.containsKey(item.productId)) {
          final existingItem = aggregatedItems[item.productId]!;
          aggregatedItems[item.productId] = OrderItem(id: existingItem.id, orderId: item.orderId, productId: item.productId, jumlah: existingItem.jumlah + item.jumlah, hargaUnit: item.hargaUnit, subtotal: existingItem.subtotal + item.subtotal, status: item.status);
        } else {
          aggregatedItems[item.productId] = item;
        }
      }
      final uniqueItemsForThisOrder = aggregatedItems.values.toList();
      uniqueItemsForThisOrder.sort((a, b) => (productMap[a.productId]?.namaProduk ?? '').compareTo(productMap[b.productId]?.namaProduk ?? ''));
      for (int i = 0; i < uniqueItemsForThisOrder.length; i++) {
        final item = uniqueItemsForThisOrder[i];
        final product = productMap[item.productId];
        final List<CellValue> rowData = (i == 0) ? [IntCellValue(order.id), TextCellValue(DateFormat('dd-MM-yyyy HH:mm').format(DateTime.parse(order.tanggalPesanan!)))] : [ TextCellValue(''),  TextCellValue('')];
        rowData.addAll([TextCellValue(product?.namaProduk ?? 'Produk ID: ${item.productId}'), IntCellValue(item.jumlah), DoubleCellValue(item.hargaUnit), DoubleCellValue(item.subtotal), TextCellValue(item.status)]);
        sheet.appendRow(rowData);
        final int currentRow = sheet.maxRows - 1;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow)).cellStyle = currencyStyle;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow)).cellStyle = currencyStyle;
      }
    }
    sheet.appendRow([]);
    sheet.appendRow([ TextCellValue(''),  TextCellValue(''),  TextCellValue(''),  TextCellValue(''),  TextCellValue('Total Pendapatan'), DoubleCellValue(totalRevenue),  TextCellValue('')]);
    final int totalRowIndex = sheet.maxRows - 1;
    final totalLabelCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: totalRowIndex));
    // PERBAIKAN SINTAKS: Ganti 'Val' dengan nama parameter yang benar
    totalLabelCell.cellStyle = totalStyle.copyWith(horizontalAlignVal: HorizontalAlign.Right, boldVal: true);
    final totalValueCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRowIndex));
    totalValueCell.cellStyle = totalStyle.copyWith(numberFormat: currencyStyle.numberFormat, boldVal: true);
    for (var i = 0; i < tableHeaders.length; i++) {
      sheet.setColumnAutoFit(i);
    }

    // Kembalikan file sebagai bytes, BUKAN menyimpannya
    return excel.encode();
  }

  // --- BAGIAN 2: FUNGSI UTILITAS PENYIMPANAN FILE ---

  // Fungsi ini berisi logika yang Anda minta untuk dihapus dari fungsi utama
  static Future<void> saveFile(List<int> fileBytes, String fileName) async {
    if (kIsWeb) {
      final blob = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)..setAttribute("download", fileName)..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/$fileName';
      final file = File(path);
      await file.writeAsBytes(fileBytes);
      await OpenFilex.open(path);
    }
  }
}