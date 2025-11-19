import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/category.dart';
import '../main.dart';
import 'package:uuid/uuid.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with SingleTickerProviderStateMixin {
  late Box categoryBox;
  final _uuid = const Uuid();
  late TabController _tabController;

  // Iconos predefinidos para categorías
  final List<CategoryIcon> categoryIcons = [
    CategoryIcon('Comida', Icons.restaurant_rounded, const Color(0xFFFF6B4A)),
    CategoryIcon('Transporte', Icons.directions_car_rounded, const Color(0xFF4AA89D)),
    CategoryIcon('Compras', Icons.shopping_bag_rounded, const Color(0xFFB548B8)),
    CategoryIcon('Entretenimiento', Icons.movie_rounded, const Color(0xFFE85D75)),
    CategoryIcon('Salud', Icons.favorite_rounded, const Color(0xFF0BA5C8)),
    CategoryIcon('Educación', Icons.school_rounded, const Color(0xFFFFC947)),
    CategoryIcon('Hogar', Icons.home_rounded, const Color(0xFF4AA89D)),
    CategoryIcon('Servicios', Icons.miscellaneous_services_rounded, const Color(0xFFFF6B4A)),
    CategoryIcon('Deporte', Icons.fitness_center_rounded, const Color(0xFFE85D75)),
    CategoryIcon('Viajes', Icons.flight_rounded, const Color(0xFF0BA5C8)),
    CategoryIcon('Mascotas', Icons.pets_rounded, const Color(0xFFB548B8)),
    CategoryIcon('Regalos', Icons.card_giftcard_rounded, const Color(0xFFFFC947)),
    CategoryIcon('Salario', Icons.attach_money_rounded, const Color(0xFF4AA89D)),
    CategoryIcon('Freelance', Icons.laptop_rounded, const Color(0xFF0BA5C8)),
    CategoryIcon('Inversiones', Icons.trending_up_rounded, const Color(0xFFB548B8)),
    CategoryIcon('Otro', Icons.more_horiz_rounded, Colors.grey),
  ];

  @override
  void initState() {
    super.initState();
    categoryBox = Hive.box('categories');
    _tabController = TabController(length: 2, vsync: this);
    _addSampleCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addSampleCategories() {
    if (categoryBox.isEmpty) {
      final samples = [
        CategoryModel(id: _uuid.v4(), nombre: 'Comida', tipo: 'egreso'),
        CategoryModel(id: _uuid.v4(), nombre: 'Transporte', tipo: 'egreso'),
        CategoryModel(id: _uuid.v4(), nombre: 'Entretenimiento', tipo: 'egreso'),
        CategoryModel(id: _uuid.v4(), nombre: 'Salario', tipo: 'ingreso'),
        CategoryModel(id: _uuid.v4(), nombre: 'Freelance', tipo: 'ingreso'),
      ];
      
      for (var cat in samples) {
        categoryBox.put(cat.id, cat);
        // Guardar el ícono por defecto
        final iconBox = Hive.box('settings');
        final defaultIcon = categoryIcons.firstWhere(
          (icon) => icon.name == cat.nombre,
          orElse: () => categoryIcons.last,
        );
        iconBox.put('category_icon_${cat.id}', defaultIcon.name);
      }
    }
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    String tipo = 'egreso';
    String? selectedIconName;
    CategoryIcon? selectedIcon;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Text(
                      'Nueva Categoría',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Campo de nombre
                      const Text(
                        'Nombre de la categoría',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'Ej: Supermercado',
                          prefixIcon: const Icon(Icons.label_rounded),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      // Tipo
                      const Text(
                        'Tipo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => tipo = 'ingreso'),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: tipo == 'ingreso' 
                                      ? AppColors.teal.withOpacity(0.1)
                                      : Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: tipo == 'ingreso' 
                                        ? AppColors.teal
                                        : Colors.grey.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.arrow_downward_rounded,
                                      color: tipo == 'ingreso' ? AppColors.teal : Colors.grey,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ingreso',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: tipo == 'ingreso' ? AppColors.teal : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => tipo = 'egreso'),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: tipo == 'egreso' 
                                      ? AppColors.red.withOpacity(0.1)
                                      : Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: tipo == 'egreso' 
                                        ? AppColors.red
                                        : Colors.grey.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.arrow_upward_rounded,
                                      color: tipo == 'egreso' ? AppColors.red : Colors.grey,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Egreso',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: tipo == 'egreso' ? AppColors.red : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Selector de ícono
                      const Text(
                        'Ícono',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                        itemCount: categoryIcons.length,
                        itemBuilder: (context, index) {
                          final icon = categoryIcons[index];
                          final isSelected = selectedIconName == icon.name;
                          
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedIconName = icon.name;
                                selectedIcon = icon;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? icon.color.withOpacity(0.2)
                                    : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? icon.color : Colors.grey.withOpacity(0.3),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    icon.icon,
                                    color: isSelected ? icon.color : Colors.grey,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    icon.name,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isSelected ? icon.color : Colors.grey,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              // Botón de guardar
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isNotEmpty) {
                          final category = CategoryModel(
                            id: _uuid.v4(),
                            nombre: nameController.text,
                            tipo: tipo,
                          );
                          
                          categoryBox.put(category.id, category);
                          
                          // Guardar el ícono seleccionado
                          if (selectedIconName != null) {
                            final iconBox = Hive.box('settings');
                            iconBox.put('category_icon_${category.id}', selectedIconName);
                          }
                          
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Crear Categoría',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  CategoryIcon _getCategoryIcon(String categoryId) {
    final iconBox = Hive.box('settings');
    final iconName = iconBox.get('category_icon_$categoryId');
    
    if (iconName != null) {
      return categoryIcons.firstWhere(
        (icon) => icon.name == iconName,
        orElse: () => categoryIcons.last,
      );
    }
    
    return categoryIcons.last;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
SliverAppBar(
  expandedHeight: 120,
  floating: false,
  pinned: true,
  backgroundColor: isDark ? AppColors.darkSurface : AppColors.orange,
  flexibleSpace: FlexibleSpaceBar(
    title: const Text(
      'Categorías',
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
    ),
    titlePadding: const EdgeInsets.only(left: 16, bottom: 60),
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
  bottom: TabBar(
    controller: _tabController,
    indicatorColor: Colors.white,
    indicatorWeight: 3,
    labelColor: Colors.white,
    unselectedLabelColor: Colors.white.withOpacity(0.6),
    labelStyle: const TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 15,
    ),
    tabs: const [
      Tab(text: 'Egresos'),
      Tab(text: 'Ingresos'),
    ],
  ),
),
          ];
        },
        body: ValueListenableBuilder(
          valueListenable: categoryBox.listenable(),
          builder: (context, box, _) {
            final categories = box.values.cast<CategoryModel>().toList();
            final ingresoCategories = categories.where((c) => c.tipo == 'ingreso').toList();
            final egresoCategories = categories.where((c) => c.tipo == 'egreso').toList();

            return TabBarView(
              controller: _tabController,
              children: [
                // Tab de Egresos
                egresoCategories.isEmpty
                    ? _buildEmptyState('egreso')
                    : _buildCategoryList(egresoCategories, isDark),
                
                // Tab de Ingresos
                ingresoCategories.isEmpty
                    ? _buildEmptyState('ingreso')
                    : _buildCategoryList(ingresoCategories, isDark),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategoryDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva Categoría'),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildCategoryList(List<CategoryModel> categories, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category, isDark);
      },
    );
  }

  Widget _buildCategoryCard(CategoryModel category, bool isDark) {
    final isIngreso = category.tipo == 'ingreso';
    final categoryIcon = _getCategoryIcon(category.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: categoryIcon.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: categoryIcon.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            categoryIcon.icon,
            color: categoryIcon.color,
            size: 28,
          ),
        ),
        title: Text(
          category.nombre,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(
                isIngreso ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                size: 14,
                color: isIngreso ? AppColors.teal : AppColors.red,
              ),
              const SizedBox(width: 4),
              Text(
                isIngreso ? 'Ingreso' : 'Egreso',
                style: TextStyle(
                  color: isIngreso ? AppColors.teal : AppColors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_rounded),
          color: Colors.red,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text('Eliminar categoría'),
                content: Text('¿Estás seguro de eliminar "${category.nombre}"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      categoryBox.delete(category.id);
                      // Eliminar también el ícono asociado
                      final iconBox = Hive.box('settings');
                      iconBox.delete('category_icon_${category.id}');
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(String tipo) {
    return Container(
      margin: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              tipo == 'ingreso' ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              size: 80,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No hay categorías de ${tipo}s',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Crea tu primera categoría de ${tipo}s\npara organizar tus transacciones',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Clase para los íconos de categorías
class CategoryIcon {
  final String name;
  final IconData icon;
  final Color color;

  CategoryIcon(this.name, this.icon, this.color);
}