import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/hive_service.dart';
import '../services/sheets_api_service.dart';
import '../models/transaction.dart';

class SyncService {
  final HiveService hiveService = HiveService();

  /// Revisar si hay internet REAL (no solo WiFi)
  Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup("google.com");
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Sincronizar SOLO las transacciones pendientes
  Future<void> syncPendingTransactions() async {
    if (await hasInternet() == false) return;

    List<TransactionModel> pending =
        hiveService.getPendingSyncTransactions();

    if (pending.isEmpty) return;

    // Enviar batch
    bool ok = await SheetsApiService.sendBatch(pending);

    if (ok) {
      // Marcar todos como sincronizados
      for (var t in pending) {
        await hiveService.markTransactionSynced(t.id);
      }
    }
  }

  /// Activar listeners automáticos
  void startAutoSync() {
    Connectivity().onConnectivityChanged.listen((status) async {
      if (status != ConnectivityResult.none) {
        await syncPendingTransactions();
      }
    });
  }
}
