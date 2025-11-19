import 'dart:convert';
import 'package:http/http.dart' as http;

class SheetsApiService {
  static const String baseUrl = ""; // Asegúrate de tener tu URL correcta

  /// ********************
  /// INSERTAR MOVIMIENTO
  /// ********************
  static Future<Map<String, dynamic>> addMovimiento({
    required String tipo,
    required double monto,
    required String descripcion,
    required String categoria,
    required String meta,
    required String fecha,
  }) async {
    try {
      final url = Uri.parse(baseUrl);

      print('🌐 Enviando a: $url');
      print('📦 Datos: tipo=$tipo, monto=$monto, desc=$descripcion');
      
      // Crear el cliente HTTP que NO siga redirecciones automáticamente
      final client = http.Client();
      
      final request = http.Request('POST', url);
      request.headers['Content-Type'] = 'application/x-www-form-urlencoded';
      request.bodyFields = {
        "action": "addMovimiento",
        "tipo": tipo,
        "monto": monto.toString(),
        "descripcion": descripcion,
        "categoria": categoria,
        "meta": meta,
        "fecha": fecha,
      };

      // Enviar sin seguir redirecciones
      final streamedResponse = await client.send(request).timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Status code: ${response.statusCode}');

      // ✅ CAMBIO IMPORTANTE: Aceptar 200, 201, 302 como éxito
      if (response.statusCode == 200 || 
          response.statusCode == 201 || 
          response.statusCode == 302) {
        
        print('✅ Petición exitosa (código ${response.statusCode})');
        
        // Intentar parsear la respuesta si es JSON
        if (response.body.isNotEmpty && !response.body.trim().startsWith('<')) {
          try {
            final decoded = jsonDecode(response.body);
            return decoded as Map<String, dynamic>;
          } catch (e) {
            // Si no se puede parsear pero el código es 302, asumir éxito
            print('⚠️ No se pudo parsear JSON pero código es ${response.statusCode}, asumiendo éxito');
            return {
              "success": true,
              "message": "Datos enviados correctamente (código ${response.statusCode})"
            };
          }
        } else {
          // Respuesta HTML o vacía con código 302 = éxito
          print('✅ Código ${response.statusCode} con respuesta HTML, asumiendo éxito');
          return {
            "success": true,
            "message": "Datos enviados correctamente"
          };
        }
      } else {
        print('❌ Código de error: ${response.statusCode}');
        return {
          "success": false,
          "error": "HTTP ${response.statusCode}"
        };
      }
    } catch (e) {
      print('❌ Excepción en addMovimiento: $e');
      return {
        "success": false,
        "error": e.toString()
      };
    }
  }

  /// ***************************************
  /// OBTENER TODOS LOS MOVIMIENTOS
  /// ***************************************
  static Future<List<dynamic>> getMovimientos() async {
    try {
      final url = Uri.parse("$baseUrl?action=getMovimientos");
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          return decoded['data'] as List<dynamic>;
        }
        return [];
      }
      return [];
    } catch (e) {
      print('Error en getMovimientos: $e');
      return [];
    }
  }

  /// ***************************************
  /// OBTENER TODAS LAS CATEGORÍAS
  /// ***************************************
  static Future<List<dynamic>> getCategorias() async {
    try {
      final url = Uri.parse("$baseUrl?action=getCategorias");
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          return decoded['data'] as List<dynamic>;
        }
        return [];
      }
      return [];
    } catch (e) {
      print('Error en getCategorias: $e');
      return [];
    }
  }

  /// ***************************************
  /// OBTENER TODAS LAS METAS
  /// ***************************************
  static Future<List<dynamic>> getMetas() async {
    try {
      final url = Uri.parse("$baseUrl?action=getMetas");
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          return decoded['data'] as List<dynamic>;
        }
        return [];
      }
      return [];
    } catch (e) {
      print('Error en getMetas: $e');
      return [];
    }
  }

  /// *****************************************
  /// ACTUALIZAR UNA META (ACUMULADO)
  /// *****************************************
  static Future<Map<String, dynamic>> actualizarMeta({
    required String metaId,
    required double nuevoAcumulado,
  }) async {
    try {
      final url = Uri.parse(baseUrl);

      final response = await http.post(
        url,
        body: {
          "action": "updateMeta",
          "id": metaId,
          "acumulado": nuevoAcumulado.toString(),
        },
      );

      // Aceptar 200, 201, 302 como éxito
      if (response.statusCode == 200 || 
          response.statusCode == 201 || 
          response.statusCode == 302) {
        
        if (response.body.isNotEmpty && !response.body.trim().startsWith('<')) {
          return jsonDecode(response.body);
        } else {
          return {"success": true, "message": "Meta actualizada"};
        }
      }

      return {"success": false, "error": "HTTP ${response.statusCode}"};
    } catch (e) {
      print('Error en actualizarMeta: $e');
      return {"success": false, "error": e.toString()};
    }
  }
}

