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
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CategoryModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(GoalModelAdapter());
    }

    await Hive.openBox<TransactionModel>(transactionsBox);
    await Hive.openBox<CategoryModel>(categoriesBox);
    await Hive.openBox<GoalModel>(goalsBox);
  }

  // ============================
  //  TRANSACTIONS CRUD
  // ============================

  Future<void> addTransaction(TransactionModel model) async {
    final box = Hive.box<TransactionModel>(transactionsBox);
    await box.put(model.id, model);
  }

  List<TransactionModel> getAllTransactions() {
    final box = Hive.box<TransactionModel>(transactionsBox);
    return box.values.toList();
  }

  Future<void> updateTransaction(TransactionModel model) async {
    final box = Hive.box<TransactionModel>(transactionsBox);
    await box.put(model.id, model);
  }

  Future<void> deleteTransaction(String id) async {
    final box = Hive.box<TransactionModel>(transactionsBox);
    await box.delete(id);
  }

  /// Obtener solo los que faltan sincronizar
  List<TransactionModel> getPendingSyncTransactions() {
    final box = Hive.box<TransactionModel>(transactionsBox);
    return box.values.where((t) => t.pendingSync == true).toList();
  }

  /// Marcar como sincronizado
  Future<void> markTransactionSynced(String id) async {
    final box = Hive.box<TransactionModel>(transactionsBox);
    final item = box.get(id);
    if (item != null) {
      item.pendingSync = false;
      await item.save();
    }
  }

  // ============================
  //  CATEGORIES CRUD
  // ============================

  Future<void> addCategory(CategoryModel model) async {
    final box = Hive.box<CategoryModel>(categoriesBox);
    await box.put(model.id, model);
  }

  List<CategoryModel> getAllCategories() {
    final box = Hive.box<CategoryModel>(categoriesBox);
    return box.values.toList();
  }

  Future<void> updateCategory(CategoryModel model) async {
    final box = Hive.box<CategoryModel>(categoriesBox);
    await box.put(model.id, model);
  }

  Future<void> deleteCategory(String id) async {
    final box = Hive.box<CategoryModel>(categoriesBox);
    await box.delete(id);
  }

  // ============================
  //  GOALS CRUD
  // ============================

  Future<void> addGoal(GoalModel model) async {
    final box = Hive.box<GoalModel>(goalsBox);
    await box.put(model.id, model);
  }

  List<GoalModel> getAllGoals() {
    final box = Hive.box<GoalModel>(goalsBox);
    return box.values.toList();
  }

  Future<void> updateGoal(GoalModel model) async {
    final box = Hive.box<GoalModel>(goalsBox);
    await box.put(model.id, model);
  }

  Future<void> deleteGoal(String id) async {
    final box = Hive.box<GoalModel>(goalsBox);
    await box.delete(id);
  }
}
