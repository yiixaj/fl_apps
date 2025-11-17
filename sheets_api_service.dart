import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';

class SheetsApiService {
  // 🔗 URL del Google Apps Script (la configuraremos después)
  static const String scriptUrl =
      "YOUR_WEB_APP_URL_HERE"; // <-- luego la reemplazas

  /// Enviar UNA transacción al Google Sheet
  static Future<bool> sendTransaction(TransactionModel t) async {
    try {
      final response = await http.post(
        Uri.parse(scriptUrl),
        body: {
          "action": "addTransaction",
          "id": t.id,
          "tipo": t.tipo,
          "monto": t.monto.toString(),
          "descripcion": t.descripcion,
          "categoria": t.categoriaId,
          "meta": t.metaId,
          "fecha": t.fecha.toIso8601String(),
        },
      );

      /// Si devuelve 200, asumimos que se guardó correctamente
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Enviar varias transacciones (pendientes)
  static Future<bool> sendBatch(List<TransactionModel> list) async {
    try {
      final payload = list
          .map((t) => {
                "id": t.id,
                "tipo": t.tipo,
                "monto": t.monto,
                "descripcion": t.descripcion,
                "categoria": t.categoriaId,
                "meta": t.metaId,
                "fecha": t.fecha.toIso8601String(),
              })
          .toList();

      final response = await http.post(
        Uri.parse(scriptUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "addBatch",
          "data": payload,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
