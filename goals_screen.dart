import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/goal.dart';
import '../main.dart';
import 'package:uuid/uuid.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  late Box goalBox;
  final _uuid = const Uuid();
  final ImagePicker _picker = ImagePicker();

  // Imágenes predefinidas para las metas
  final List<GoalImage> goalImages = [
    GoalImage('Auto', 'https://images.unsplash.com/photo-1494976388531-d1058494cdd8?w=800', Icons.directions_car_rounded),
    GoalImage('Casa', 'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=800', Icons.home_rounded),
    GoalImage('Vacaciones', 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800', Icons.beach_access_rounded),
    GoalImage('Educación', 'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=800', Icons.school_rounded),
    GoalImage('Inversión', 'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=800', Icons.trending_up_rounded),
    GoalImage('Boda', 'https://images.unsplash.com/photo-1519741497674-611481863552?w=800', Icons.favorite_rounded),
    GoalImage('Tecnología', 'https://images.unsplash.com/photo-1468495244123-6c6c332eeece?w=800', Icons.devices_rounded),
    GoalImage('Salud', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800', Icons.fitness_center_rounded),
    GoalImage('Negocio', 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=800', Icons.business_rounded),
    GoalImage('Otro', 'https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?w=800', Icons.star_rounded),
  ];

  @override
  void initState() {
    super.initState();
    goalBox = Hive.box('goals');
    _addSampleGoals();
  }

  void _addSampleGoals() {
    if (goalBox.isEmpty) {
      final imageBox = Hive.box('settings');
      
      final samples = [
        {
          'goal': GoalModel(
            id: _uuid.v4(),
            nombre: 'Fondo de Emergencia',
            objetivo: 5000.0,
            acumulado: 1500.0,
          ),
          'imageUrl': 'https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?w=800',
        },
        {
          'goal': GoalModel(
            id: _uuid.v4(),
            nombre: 'Vacaciones',
            objetivo: 2000.0,
            acumulado: 500.0,
          ),
          'imageUrl': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
        },
      ];
      
      for (var sample in samples) {
        final goal = sample['goal'] as GoalModel;
        final imageUrl = sample['imageUrl'] as String;
        
        goalBox.put(goal.id, goal);
        imageBox.put('goal_image_${goal.id}', imageUrl);
      }
    }
  }

  Future<void> _pickImageFromGallery(Function(String) onImageSelected) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (image != null) {
        onImageSelected(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera(Function(String) onImageSelected) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (image != null) {
        onImageSelected(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al tomar foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog(Function(String) onImageSelected) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Seleccionar imagen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.purple),
                ),
                title: const Text('Galería'),
                subtitle: const Text('Seleccionar desde tu galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery(onImageSelected);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.blue),
                ),
                title: const Text('Cámara'),
                subtitle: const Text('Tomar una foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera(onImageSelected);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddGoalDialog() {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    String? selectedImageUrl;
    String? customImagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.98,
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
                      'Nueva Meta',
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
                        'Nombre de la meta',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'Ej: Comprar un auto',
                          prefixIcon: const Icon(Icons.flag_rounded),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      // Campo de monto
                      const Text(
                        'Monto objetivo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: targetController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '0.00',
                          prefixIcon: const Icon(Icons.attach_money_rounded),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Botón para subir imagen propia
                      Row(
                        children: [
                          const Text(
                            'Imagen de fondo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              _showImageSourceDialog((imagePath) {
                                setModalState(() {
                                  customImagePath = imagePath;
                                  selectedImageUrl = null; // Deseleccionar predefinidas
                                });
                              });
                            },
                            icon: const Icon(Icons.add_photo_alternate_rounded),
                            label: const Text('Subir imagen'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.orange,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),

                      // Mostrar imagen personalizada si existe
                      if (customImagePath != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.orange,
                              width: 3,
                            ),
                            image: DecorationImage(
                              image: FileImage(File(customImagePath!)),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.black.withOpacity(0.3),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.orange,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Tu imagen',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.red,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          setModalState(() {
                                            customImagePath = null;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Imagen seleccionada',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Divisor solo si hay imagen personalizada
                      if (customImagePath != null) ...[
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[300])),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'o elige una predefinida',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey[300])),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Grid de imágenes predefinidas
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                        itemCount: goalImages.length,
                        itemBuilder: (context, index) {
                          final image = goalImages[index];
                          final isSelected = selectedImageUrl == image.url && customImagePath == null;
                          
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedImageUrl = image.url;
                                customImagePath = null; // Deseleccionar imagen personalizada
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? AppColors.orange : Colors.grey.withOpacity(0.3),
                                  width: isSelected ? 3 : 1,
                                ),
                                image: DecorationImage(
                                  image: NetworkImage(image.url),
                                  fit: BoxFit.cover,
                                  colorFilter: ColorFilter.mode(
                                    Colors.black.withOpacity(0.3),
                                    BlendMode.darken,
                                  ),
                                ),
                              ),
                              child: Stack(
                                children: [
                                  if (isSelected)
                                    const Positioned(
                                      top: 8,
                                      right: 8,
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: AppColors.orange,
                                        child: Icon(
                                          Icons.check_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          image.icon,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          image.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
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
                        if (nameController.text.isNotEmpty && targetController.text.isNotEmpty) {
                          final goal = GoalModel(
                            id: _uuid.v4(),
                            nombre: nameController.text,
                            objetivo: double.parse(targetController.text),
                            acumulado: 0.0,
                          );
                          
                          final imageBox = Hive.box('settings');
                          
                          // Guardar imagen personalizada o predefinida
                          if (customImagePath != null) {
                            imageBox.put('goal_image_${goal.id}', 'file://$customImagePath');
                          } else if (selectedImageUrl != null) {
                            imageBox.put('goal_image_${goal.id}', selectedImageUrl);
                          }
                          
                          goalBox.put(goal.id, goal);
                          Navigator.pop(context);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✓ Meta creada exitosamente'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.teal,
                            ),
                          );
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
                        'Crear Meta',
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

  void _showAddMoneyDialog(GoalModel goal) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.teal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Agregar a: ${goal.nombre}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Monto a agregar',
            prefixIcon: const Icon(Icons.attach_money_rounded),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (amountController.text.isNotEmpty) {
                final amount = double.parse(amountController.text);
                goal.acumulado += amount;
                goal.save();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  String? _getGoalImage(String goalId) {
    final imageBox = Hive.box('settings');
    return imageBox.get('goal_image_$goalId');
  }

  ImageProvider _getImageProvider(String? imageUrl) {
    if (imageUrl == null) {
      return const NetworkImage('https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?w=800');
    }
    
    if (imageUrl.startsWith('file://')) {
      return FileImage(File(imageUrl.substring(7)));
    }
    
    return NetworkImage(imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.orange,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Mis Metas',
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
          ),
          SliverToBoxAdapter(
            child: ValueListenableBuilder(
              valueListenable: goalBox.listenable(),
              builder: (context, box, _) {
                final goals = box.values.cast<GoalModel>().toList();

                if (goals.isEmpty) {
                  return _buildEmptyState();
                }

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsCard(goals),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Todas las metas',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${goals.length} ${goals.length == 1 ? 'meta' : 'metas'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...goals.map((goal) => _buildGoalCard(goal, isDark)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGoalDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva Meta'),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatsCard(List<GoalModel> goals) {
    final totalObjetivo = goals.fold<double>(0, (sum, g) => sum + g.objetivo);
    final totalAcumulado = goals.fold<double>(0, (sum, g) => sum + g.acumulado);
    final progress = totalObjetivo > 0 ? (totalAcumulado / totalObjetivo) : 0.0;
    final completedGoals = goals.where((g) => g.acumulado >= g.objetivo).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.purple, AppColors.blue],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progreso General',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$completedGoals/${goals.length} completadas',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '\$${totalAcumulado.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'de \$${totalObjetivo.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toStringAsFixed(1)}% del total',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(GoalModel goal, bool isDark) {
    final progress = goal.acumulado / goal.objetivo;
    final percentage = (progress * 100).clamp(0, 100).toStringAsFixed(1);
    final isCompleted = progress >= 1.0;
    final imageUrl = _getGoalImage(goal.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: imageUrl != null
            ? DecorationImage(
                image: _getImageProvider(imageUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.5),
                  BlendMode.darken,
                ),
              )
            : null,
        gradient: imageUrl == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.teal.withOpacity(0.8),
                  AppColors.blue.withOpacity(0.8),
                ],
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Botón de eliminar
          Positioned(
            top: 12,
            right: 12,
            child: IconButton(
              icon: const Icon(Icons.delete_rounded, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Eliminar meta'),
                    content: Text('¿Estás seguro de eliminar "${goal.nombre}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          goalBox.delete(goal.id);
                          final imageBox = Hive.box('settings');
                          imageBox.delete('goal_image_${goal.id}');
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Eliminar',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Contenido
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge de completado
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Completada',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                const Spacer(),

                // Nombre de la meta
                Text(
                  goal.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Progreso
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${goal.acumulado.toStringAsFixed(2)} de \$${goal.objetivo.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isCompleted ? Colors.green : Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$percentage% completado',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: isCompleted ? null : () => _showAddMoneyDialog(goal),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add_rounded, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'Agregar',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(40),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.flag_rounded,
              size: 80,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No tienes metas aún',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Crea tu primera meta financiera\ny comienza a ahorrar',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showAddGoalDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Crear Meta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Clase para las imágenes de metas
class GoalImage {
  final String name;
  final String url;
  final IconData icon;

  GoalImage(this.name, this.url, this.icon);
}
