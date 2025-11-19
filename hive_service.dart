import 'package:hive/hive.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/goal.dart';

class HiveService {
  // Nombre de las cajas
  static const String transactionsBox = "transactions";
  static const String categoriesBox = "categories";
  static const String goalsBox = "goals";

  /// Inicializar Hive y registrar adaptadores
  static Future<void> init() async {
    // REGISTRO CORREGIDO DE typeId
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TransactionModelAdapter()); // typeId: 0
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CategoryModelAdapter()); // typeId: 1
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(GoalModelAdapter()); // typeId: 2
    }

    // Abrir sin tipo específico
    await Hive.openBox(transactionsBox);
    await Hive.openBox(categoriesBox);
    await Hive.openBox(goalsBox);
  }

  // ============================
  //  TRANSACTIONS CRUD
  // ============================

  Future<void> addTransaction(TransactionModel model) async {
    final box = Hive.box(transactionsBox);
    await box.put(model.id, model);
  }

  List<TransactionModel> getAllTransactions() {
    final box = Hive.box(transactionsBox);
    return box.values.cast<TransactionModel>().toList();
  }

  Future<void> updateTransaction(TransactionModel model) async {
    final box = Hive.box(transactionsBox);
    await box.put(model.id, model);
  }

  Future<void> deleteTransaction(String id) async {
    final box = Hive.box(transactionsBox);
    await box.delete(id);
  }

  /// Obtener solo los que faltan sincronizar
  List<TransactionModel> getPendingSyncTransactions() {
    final box = Hive.box(transactionsBox);
    return box.values
        .cast<TransactionModel>()
        .where((t) => t.pendingSync == true)
        .toList();
  }

  /// Marcar como sincronizado
  Future<void> markTransactionSynced(String id) async {
    final box = Hive.box(transactionsBox);
    final item = box.get(id) as TransactionModel?;
    if (item != null) {
      item.pendingSync = false;
      await box.put(id, item);
    }
  }

  // ============================
  //  CATEGORIES CRUD
  // ============================

  Future<void> addCategory(CategoryModel model) async {
    final box = Hive.box(categoriesBox);
    await box.put(model.id, model);
  }

  List<CategoryModel> getAllCategories() {
    final box = Hive.box(categoriesBox);
    return box.values.cast<CategoryModel>().toList();
  }

  Future<void> updateCategory(CategoryModel model) async {
    final box = Hive.box(categoriesBox);
    await box.put(model.id, model);
  }

  Future<void> deleteCategory(String id) async {
    final box = Hive.box(categoriesBox);
    await box.delete(id);
  }

  // ============================
  //  GOALS CRUD
  // ============================

  Future<void> addGoal(GoalModel model) async {
    final box = Hive.box(goalsBox);
    await box.put(model.id, model);
  }

  List<GoalModel> getAllGoals() {
    final box = Hive.box(goalsBox);
    return box.values.cast<GoalModel>().toList();
  }

  Future<void> updateGoal(GoalModel model) async {
    final box = Hive.box(goalsBox);
    await box.put(model.id, model);
  }

  Future<void> deleteGoal(String id) async {
    final box = Hive.box(goalsBox);
    await box.delete(id);
  }
}
