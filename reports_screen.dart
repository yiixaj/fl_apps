import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Box transactionBox;
  String selectedPeriod = 'Mes'; // Mes, Semana, Año

  @override
  void initState() {
    super.initState();
    transactionBox = Hive.box('transactions');
  }

  List<TransactionModel> getFilteredTransactions() {
    final now = DateTime.now();
    final items = transactionBox.values.cast<TransactionModel>().toList();

    return items.where((t) {
      switch (selectedPeriod) {
        case 'Semana':
          return t.fecha.isAfter(now.subtract(const Duration(days: 7)));
        case 'Mes':
          return t.fecha.month == now.month && t.fecha.year == now.year;
        case 'Año':
          return t.fecha.year == now.year;
        default:
          return true;
      }
    }).toList();
  }

  Map<String, double> getIncomeExpenseByDay() {
    final filtered = getFilteredTransactions();
    Map<String, double> ingresos = {};
    Map<String, double> egresos = {};

    for (var t in filtered) {
      final day = DateFormat('dd/MM').format(t.fecha);
      
      if (t.tipo == 'ingreso') {
        ingresos[day] = (ingresos[day] ?? 0) + t.monto;
      } else {
        egresos[day] = (egresos[day] ?? 0) + t.monto;
      }
    }

    return {'ingresos': ingresos.values.fold(0.0, (a, b) => a + b),
            'egresos': egresos.values.fold(0.0, (a, b) => a + b)};
  }

  List<FlSpot> getIncomeSpots() {
    final filtered = getFilteredTransactions()
        .where((t) => t.tipo == 'ingreso')
        .toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));

    Map<int, double> dailyIncome = {};
    for (var t in filtered) {
      final dayIndex = t.fecha.day;
      dailyIncome[dayIndex] = (dailyIncome[dayIndex] ?? 0) + t.monto;
    }

    return dailyIncome.entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
  }

  List<FlSpot> getExpenseSpots() {
    final filtered = getFilteredTransactions()
        .where((t) => t.tipo == 'egreso')
        .toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));

    Map<int, double> dailyExpense = {};
    for (var t in filtered) {
      final dayIndex = t.fecha.day;
      dailyExpense[dayIndex] = (dailyExpense[dayIndex] ?? 0) + t.monto;
    }

    return dailyExpense.entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes Financieros'),
        centerTitle: true,
      ),
      body: ValueListenableBuilder(
        valueListenable: transactionBox.listenable(),
        builder: (context, box, _) {
          final stats = getIncomeExpenseByDay();
          final totalIngresos = stats['ingresos'] ?? 0;
          final totalEgresos = stats['egresos'] ?? 0;
          final balance = totalIngresos - totalEgresos;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selector de período
                _buildPeriodSelector(),
                
                const SizedBox(height: 20),

                // Resumen de números
                _buildSummaryCards(totalIngresos, totalEgresos, balance),

                const SizedBox(height: 30),

                // Gráfico de pastel
                const Text(
                  'Distribución',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                _buildPieChart(totalIngresos, totalEgresos),

                const SizedBox(height: 30),

                // Gráfico de líneas
                const Text(
                  'Tendencia del período',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                _buildLineChart(),

                const SizedBox(height: 30),

                // Categorías más gastadas
                _buildTopCategories(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['Semana', 'Mes', 'Año'].map((period) {
            final isSelected = selectedPeriod == period;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(period),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => selectedPeriod = period);
                  },
                  selectedColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(double ingresos, double egresos, double balance) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard('Ingresos', ingresos, Colors.green, Icons.arrow_downward),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard('Egresos', egresos, Colors.red, Icons.arrow_upward),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard('Balance', balance, balance >= 0 ? Colors.blue : Colors.orange, Icons.account_balance_wallet),
        ),
      ],
    );
  }

  Widget _summaryCard(String label, double value, Color color, IconData icon) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${value.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(double ingresos, double egresos) {
    final total = ingresos + egresos;
    
    if (total == 0) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No hay datos para mostrar')),
      );
    }

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              color: Colors.green,
              value: ingresos,
              title: '${(ingresos / total * 100).toStringAsFixed(1)}%',
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            PieChartSectionData(
              color: Colors.red,
              value: egresos,
              title: '${(egresos / total * 100).toStringAsFixed(1)}%',
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    final incomeSpots = getIncomeSpots();
    final expenseSpots = getExpenseSpots();

    if (incomeSpots.isEmpty && expenseSpots.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No hay datos para mostrar')),
      );
    }

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 50,
            verticalInterval: 5,
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '\$${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            if (incomeSpots.isNotEmpty)
              LineChartBarData(
                spots: incomeSpots,
                isCurved: true,
                color: Colors.green,
                barWidth: 3,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.green.withOpacity(0.1),
                ),
              ),
            if (expenseSpots.isNotEmpty)
              LineChartBarData(
                spots: expenseSpots,
                isCurved: true,
                color: Colors.red,
                barWidth: 3,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.red.withOpacity(0.1),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCategories() {
    final filtered = getFilteredTransactions();
    Map<String, double> categoryTotals = {};

    for (var t in filtered) {
      if (t.tipo == 'egreso') {
        final cat = t.categoriaId.isEmpty ? 'Sin categoría' : t.categoriaId;
        categoryTotals[cat] = (categoryTotals[cat] ?? 0) + t.monto;
      }
    }

    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No hay gastos por categoría'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Gastos por Categoría',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        ...sorted.take(5).map((entry) => Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.shade100,
              child: const Icon(Icons.category, color: Colors.red),
            ),
            title: Text(entry.key),
            trailing: Text(
              '\$${entry.value.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        )),
      ],
    );
  }
}
