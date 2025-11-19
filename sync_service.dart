import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/hive_service.dart';
import '../services/sheets_api_service.dart';
import '../models/transaction.dart';

class SyncService {
  final HiveService hiveService;

  SyncService({required this.hiveService});

  /// Verifica si hay internet real
  Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup("google.com");
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Sincroniza solo las transacciones pendientes
  Future<void> syncPendingTransactions() async {
    if (!await hasInternet()) {
      throw Exception('Sin conexión a internet');
    }

    final List<TransactionModel> pending =
        hiveService.getPendingSyncTransactions();

    if (pending.isEmpty) {
      throw Exception('No hay transacciones pendientes');
    }

    print('📤 Sincronizando ${pending.length} transacciones...');

    int successCount = 0;
    String? lastError;

    for (var t in pending) {
      try {
        print('Enviando: ${t.descripcion} - \$${t.monto}');
        
        final result = await SheetsApiService.addMovimiento(
          tipo: t.tipo,
          monto: t.monto,
          descripcion: t.descripcion,
          categoria: t.categoriaId,
          meta: t.metaId,
          fecha: t.fecha.toIso8601String().substring(0, 10), // YYYY-MM-DD
        );

        print('Respuesta: $result');

        // Verificar si fue exitoso (acepta varias respuestas posibles)
        if (result["success"] == true || 
            result["status"] == "success" ||
            result["result"] == "success") {
          await hiveService.markTransactionSynced(t.id);
          successCount++;
          print('✅ Sincronizada: ${t.descripcion}');
        } else {
          lastError = result["message"]?.toString() ?? 
                     result["error"]?.toString() ?? 
                     'Error desconocido';
          print('❌ Error: $lastError');
        }
      } catch (e) {
        lastError = e.toString();
        print('❌ Excepción: $e');
        // Continuar con la siguiente transacción
      }
    }

    if (successCount == 0) {
      throw Exception('No se pudo sincronizar ninguna transacción. Último error: $lastError');
    } else if (successCount < pending.length) {
      throw Exception('Solo se sincronizaron $successCount de ${pending.length} transacciones');
    }

    print('✅ Todas las transacciones sincronizadas correctamente');
  }

  /// Auto-sync cuando regresa internet
  void startAutoSync() {
    Connectivity().onConnectivityChanged.listen((status) async {
      if (status != ConnectivityResult.none) {
        try {
          await syncPendingTransactions();
          print('✅ Auto-sync completado');
        } catch (e) {
          print('❌ Error en auto-sync: $e');
        }
      }
    });
  }
}
