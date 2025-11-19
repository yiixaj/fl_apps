import 'package:hive/hive.dart';
part 'goal.g.dart';

@HiveType(typeId: 2)
class GoalModel extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String nombre;
  @HiveField(2) double objetivo;
  @HiveField(3) double acumulado;

  GoalModel({required this.id, required this.nombre, required this.objetivo, this.acumulado = 0});
}
