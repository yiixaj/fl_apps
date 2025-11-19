import 'package:hive/hive.dart';
part 'transaction.g.dart';

@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String tipo;
  @HiveField(2) double monto;
  @HiveField(3) String descripcion;
  @HiveField(4) String categoriaId;
  @HiveField(5) String metaId;
  @HiveField(6) DateTime fecha;
  @HiveField(7) bool pendingSync;

  TransactionModel({
    required this.id,
    required this.tipo,
    required this.monto,
    required this.descripcion,
    required this.categoriaId,
    required this.metaId,
    required this.fecha,
    this.pendingSync = false,
  });
}
