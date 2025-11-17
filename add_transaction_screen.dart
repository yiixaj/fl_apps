import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/transaction.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  String tipo = "ingreso";
  double? monto;
  String descripcion = "";
  String categoria = "";
  String meta = "";
  DateTime fecha = DateTime.now();

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // --- SAVE ---
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    final model = TransactionModel(
      id: _uuid.v4(),
      tipo: tipo,
      monto: monto!,
      descripcion: descripcion,
      categoriaId: categoria,
      metaId: meta,
      fecha: fecha,
      pendingSync: true,
    );

    // Guardar en Hive: usar la caja 'transactions' y poner con la key = id
    final box = Hive.box<TransactionModel>('transactions');
    await box.put(model.id, model);

    // Opcional: si tienes un SyncService o una cola, puedes encolar aquí.
    // await syncService.queuePending(...)

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat("dd MMM yyyy").format(fecha);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Nueva Transacción",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(children: [
                // Tipo (Ingreso / Egreso)
                buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Tipo", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text("Ingreso"),
                              selected: tipo == "ingreso",
                              selectedColor: Colors.greenAccent,
                              onSelected: (v) => setState(() => tipo = "ingreso"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text("Egreso"),
                              selected: tipo == "egreso",
                              selectedColor: Colors.redAccent,
                              onSelected: (v) => setState(() => tipo = "egreso"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Monto
                buildCard(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Monto",
                      prefixIcon: Icon(Icons.attach_money),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(fontSize: 18),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Ingresa un monto";
                      final parsed = double.tryParse(v.replaceAll(',', '.'));
                      if (parsed == null) return "Monto inválido";
                      return null;
                    },
                    onSaved: (v) => monto = double.parse(v!.replaceAll(',', '.')),
                  ),
                ),

                // Descripción
                buildCard(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Descripción",
                      prefixIcon: Icon(Icons.edit),
                      border: InputBorder.none,
                    ),
                    onSaved: (v) => descripcion = v ?? "",
                  ),
                ),

                // Categoria (texto por ahora)
                buildCard(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Categoría (por ahora texto)",
                      prefixIcon: Icon(Icons.category),
                      border: InputBorder.none,
                    ),
                    onSaved: (v) => categoria = v ?? "",
                  ),
                ),

                // Meta (opcional)
                buildCard(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Meta (opcional)",
                      prefixIcon: Icon(Icons.flag),
                      border: InputBorder.none,
                    ),
                    onSaved: (v) => meta = v ?? "",
                  ),
                ),

                // Fecha
                buildCard(
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Fecha: $dateFormatted",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: fecha,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (selected != null) {
                            setState(() => fecha = selected);
                          }
                        },
                        child: const Text("Cambiar"),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Guardar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "Guardar Transacción",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
