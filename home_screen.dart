import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/transaction.dart';
import '../services/hive_service.dart';
import '../services/sync_service.dart';
import 'add_transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  final HiveService hiveService;
  final SyncService syncService;

  const HomeScreen({
    super.key,
    required this.hiveService,
    required this.syncService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box transactionBox;

  @override
  void initState() {
    super.initState();
    transactionBox = Hive.box('transactions');
  }

  double getTotalIngresos() {
    final items = transactionBox.values.cast<TransactionModel>();
    return items
        .where((t) => t.tipo == "ingreso")
        .fold(0.0, (sum, t) => sum + t.monto);
  }

  double getTotalEgresos() {
    final items = transactionBox.values.cast<TransactionModel>();
    return items
        .where((t) => t.tipo == "egreso")
        .fold(0.0, (sum, t) => sum + t.monto);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Finanzas"),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              // Llamamos al método existente que ya tienes en SyncService
              try {
                await widget.syncService.syncPendingTransactions();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Sincronización completada")),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error al sincronizar: $e")),
                );
              }
            },
          ),
        ],
      ),

      // BOTÓN PARA AGREGAR TRANSACCIÓN
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Tu AddTransactionScreen actual no espera parámetros, así que la abrimos directamente
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddTransactionScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),

      body: ValueListenableBuilder(
        valueListenable: transactionBox.listenable(),
        builder: (context, box, _) {
          final items = box.values.cast<TransactionModel>().toList();
          items.sort((a, b) => b.fecha.compareTo(a.fecha));

          final ingresos = getTotalIngresos();
          final egresos = getTotalEgresos();
          final balance = ingresos - egresos;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // RESUMEN
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        "Resumen financiero",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      _summaryRow("Ingresos", ingresos, Colors.green),
                      const SizedBox(height: 10),
                      _summaryRow("Egresos", egresos, Colors.red),
                      const Divider(),
                      _summaryRow("Balance", balance,
                          balance >= 0 ? Colors.blue : Colors.red),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Transacciones recientes",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              ...items.map((t) => _transactionTile(t)),
            ],
          );
        },
      ),
    );
  }

  // TILE DE CADA TRANSACCIÓN
  Widget _transactionTile(TransactionModel t) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: t.tipo == "ingreso" ? Colors.green : Colors.red,
          child: Icon(
            t.tipo == "ingreso" ? Icons.arrow_downward : Icons.arrow_upward,
            color: Colors.white,
          ),
        ),
        title: Text(t.descripcion.isEmpty ? "(Sin descripción)" : t.descripcion),
        subtitle: Text(t.fecha.toLocal().toString().split(".")[0]),
        trailing: Text(
          "\$${t.monto.toStringAsFixed(2)}",
          style: TextStyle(
            color: t.tipo == "ingreso" ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // FILA DE RESUMEN
  Widget _summaryRow(String label, double value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          "\$${value.toStringAsFixed(2)}",
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
