import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../services/hive_service.dart';
import '../services/sync_service.dart';
import '../main.dart';
import 'add_transaction_screen.dart';
import 'reports_screen.dart';
import 'categories_screen.dart';
import 'goals_screen.dart';

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
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AddTransactionScreen(),
        ),
      ).then((_) {
        setState(() => _selectedIndex = 0);
      });
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _DashboardTab(
        hiveService: widget.hiveService,
        syncService: widget.syncService,
      ),
      const SizedBox(),
      const GoalsScreen(),
      const CategoriesScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex == 1 ? 0 : _selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_rounded),
              label: 'Registrar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.flag_rounded),
              label: 'Metas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.category_rounded),
              label: 'Categorías',
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  final HiveService hiveService;
  final SyncService syncService;

  const _DashboardTab({
    required this.hiveService,
    required this.syncService,
  });

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  late Box transactionBox;
  String selectedPeriod = 'Este mes';

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
        case 'Hoy':
          return t.fecha.day == now.day &&
              t.fecha.month == now.month &&
              t.fecha.year == now.year;
        case 'Esta semana':
          final weekAgo = now.subtract(const Duration(days: 7));
          return t.fecha.isAfter(weekAgo);
        case 'Este mes':
          return t.fecha.month == now.month && t.fecha.year == now.year;
        case 'Este año':
          return t.fecha.year == now.year;
        default:
          return true;
      }
    }).toList();
  }

  double getTotalIngresos() {
    final items = getFilteredTransactions();
    return items
        .where((t) => t.tipo == "ingreso")
        .fold(0.0, (sum, t) => sum + t.monto);
  }

  double getTotalEgresos() {
    final items = getFilteredTransactions();
    return items
        .where((t) => t.tipo == "egreso")
        .fold(0.0, (sum, t) => sum + t.monto);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar profesional con efecto glass
          SliverAppBar(
            expandedHeight: 85,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.orange,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text(
                'Dashboard',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [AppColors.darkSurface, AppColors.darkBackground]
                        : [AppColors.orange, AppColors.red],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                tooltip: isDark ? 'Modo Claro' : 'Modo Oscuro',
                onPressed: () => themeProvider?.toggleTheme(),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // Notificaciones
                },
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert_rounded),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: ListTile(
                      leading: const Icon(Icons.bar_chart_rounded),
                      title: const Text('Reportes'),
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ReportsScreen()),
                        );
                      },
                    ),
                  ),
                  PopupMenuItem(
                    child: ListTile(
                      leading: const Icon(Icons.sync_rounded),
                      title: const Text('Sincronizar'),
                      contentPadding: EdgeInsets.zero,
                      onTap: () async {
                        Navigator.pop(context);
                        try {
                          await widget.syncService.syncPendingTransactions();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("✓ Sincronización completada"),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Error: $e"),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: ValueListenableBuilder(
              valueListenable: transactionBox.listenable(),
              builder: (context, box, _) {
                final items = getFilteredTransactions();
                items.sort((a, b) => b.fecha.compareTo(a.fecha));

                final ingresos = getTotalIngresos();
                final egresos = getTotalEgresos();
                final balance = ingresos - egresos;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filtro de período
                    _buildPeriodFilter(),

                    const SizedBox(height: 20),

                    // Card principal de balance - Estilo Monarch
                    _buildBalanceCard(balance, ingresos, egresos, isDark),

                    const SizedBox(height: 24),

                    // Stats cards en grid
                    _buildStatsGrid(ingresos, egresos),

                    const SizedBox(height: 24),

                    // Header de transacciones
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Transacciones recientes',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              // Ver todas
                            },
                            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                            label: const Text('Ver todas'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Lista de transacciones mejorada
                    if (items.isEmpty)
                      _buildEmptyState()
                    else
                      ...items.take(10).map((t) => _buildTransactionTile(t, isDark)),

                    const SizedBox(height: 100),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: ['Hoy', 'Esta semana', 'Este mes', 'Este año'].map((period) {
          final isSelected = selectedPeriod == period;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(period),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => selectedPeriod = period);
              },
              selectedColor: AppColors.orange,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBalanceCard(double balance, double ingresos, double egresos, bool isDark) {
    final isPositive = balance >= 0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.darkSurface, AppColors.darkSurfaceVariant]
              : isPositive
                  ? [AppColors.teal, AppColors.teal.withOpacity(0.8)]
                  : [AppColors.red, AppColors.red.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? AppColors.teal : AppColors.red).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Balance $selectedPeriod',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '\$${balance.abs().toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isPositive ? 'Superávit' : 'Déficit',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'Ingresos',
                  ingresos,
                  Icons.arrow_downward_rounded,
                  Colors.white,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildMiniStat(
                  'Gastos',
                  egresos,
                  Icons.arrow_upward_rounded,
                  Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, double value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color.withOpacity(0.9)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(double ingresos, double egresos) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Promedio Diario',
              '\$${(ingresos / 30).toStringAsFixed(2)}',
              Icons.calendar_today_rounded,
              AppColors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Transacciones',
              '${getFilteredTransactions().length}',
              Icons.receipt_long_rounded,
              AppColors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

Widget _buildTransactionTile(TransactionModel t, bool isDark) {
  final isIngreso = t.tipo == "ingreso";
  
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.grey.withOpacity(0.1),
        width: 1,
      ),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: (isIngreso ? AppColors.teal : AppColors.red).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isIngreso ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
          color: isIngreso ? AppColors.teal : AppColors.red,
          size: 24,
        ),
      ),
      title: Text(
        t.descripcion.isEmpty ? "(Sin descripción)" : t.descripcion,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column( // ✅ Cambiado de Row a Column
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMM dd, yyyy').format(t.fecha), // ✅ Formato más corto
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            if (t.categoriaId.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  t.categoriaId,
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
      trailing: Text(
        '${isIngreso ? '+' : '-'}\$${t.monto.toStringAsFixed(2)}',
        style: TextStyle(
          color: isIngreso ? AppColors.teal : AppColors.red,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay transacciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comienza agregando tu primera transacción',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
