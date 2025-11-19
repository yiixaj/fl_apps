import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/transaction.dart';
import '../models/goal.dart';
import '../models/category.dart';

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
  String? selectedCategoria;
  String? selectedMeta;
  DateTime fecha = DateTime.now();

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  late Box goalBox;
  late Box categoryBox;

  List<GoalModel> availableGoals = [];
  List<CategoryModel> availableCategories = [];

  @override
  void initState() {
    super.initState();
    
    goalBox = Hive.box('goals');
    categoryBox = Hive.box('categories');
    
    _loadData();

    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  void _loadData() {
    availableGoals = goalBox.values.cast<GoalModel>().toList();
    availableCategories = categoryBox.values.cast<CategoryModel>().toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildCard({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow:  [
          BoxShadow(
            color:isDark ? Colors.black26 : Colors.grey.withOpacity(0.2),
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
      categoriaId: selectedCategoria ?? '',
      metaId: selectedMeta ?? '',
      fecha: fecha,
      pendingSync: true,
    );

    // Guardar en Hive
    final box = Hive.box('transactions');
    await box.put(model.id, model);

    // Si es un ingreso y tiene meta asociada, actualizar la meta
    if (tipo == 'ingreso' && selectedMeta != null && selectedMeta!.isNotEmpty) {
      final goal = goalBox.get(selectedMeta);
      if (goal != null) {
        goal.acumulado += monto!;
        await goal.save();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Meta "${goal.nombre}" actualizada: +\$${monto!.toStringAsFixed(2)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }

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
      backgroundColor: Theme.of(  context).scaffoldBackgroundColor,
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
                      const Text("Tipo",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text("Ingreso"),
                              selected: tipo == "ingreso",
                              selectedColor: Colors.greenAccent,
                              onSelected: (v) => setState(() {
                                tipo = "ingreso";
                                selectedCategoria = null;
                              }),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text("Egreso"),
                              selected: tipo == "egreso",
                              selectedColor: Colors.redAccent,
                              onSelected: (v) => setState(() {
                                tipo = "egreso";
                                selectedCategoria = null;
                                selectedMeta = null; // Los egresos no afectan metas
                              }),
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
                    onSaved: (v) =>
                        monto = double.parse(v!.replaceAll(',', '.')),
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

                // Categoría (Dropdown)
                buildCard(
                  child: DropdownButtonFormField<String>(
                    value: selectedCategoria,
                    decoration: const InputDecoration(
                      labelText: "Categoría",
                      prefixIcon: Icon(Icons.category),
                      border: InputBorder.none,
                    ),
                    hint: const Text('Selecciona una categoría'),
                    items: availableCategories
                        .where((cat) => cat.tipo == tipo)
                        .map((cat) => DropdownMenuItem(
                              value: cat.id,
                              child: Text(cat.nombre),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => selectedCategoria = value);
                    },
                  ),
                ),

                // Meta (Dropdown) - Solo para ingresos
                if (tipo == 'ingreso')
                  buildCard(
                    child: DropdownButtonFormField<String>(
                      value: selectedMeta,
                      decoration: const InputDecoration(
                        labelText: "Meta (opcional)",
                        prefixIcon: Icon(Icons.flag),
                        border: InputBorder.none,
                        helperText: 'El monto se sumará a la meta seleccionada',
                        helperMaxLines: 2,
                      ),
                      hint: const Text('Selecciona una meta'),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Sin meta'),
                        ),
                        ...availableGoals.map((goal) {
                          final progress =
                              (goal.acumulado / goal.objetivo * 100)
                                  .clamp(0, 100)
                                  .toStringAsFixed(0);
                          return DropdownMenuItem(
                            value: goal.id,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text( goal.nombre, overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('($progress%)',
                                  style: TextStyle(
                                    fontSize: 12,
                                      color: progress == '100' ? Colors.green : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                  ),
                              ),
                            ],  
                          ),
                        );
                      }),
                    ],
                    selectedItemBuilder: (BuildContext context) {
                      return [
                        const Text('Sin meta'),
                        ...availableGoals.map((goal) {
                          final progress =
                              (goal.acumulado / goal.objetivo * 100)
                                  .clamp(0, 100)
                                  .toStringAsFixed(0);
                          return Text(
                            '${goal.nombre} ($progress%)',
                            overflow: TextOverflow.ellipsis,
                          );
                        }),
                      ];
                    },
                    onChanged: (value) {
                      setState(() => selectedMeta = value);
                    },
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
