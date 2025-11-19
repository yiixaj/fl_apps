import 'package:hive/hive.dart';
part 'category.g.dart';

@HiveType(typeId: 1)
class CategoryModel extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String nombre;
  @HiveField(2) String tipo;

  CategoryModel({
    required this.id,
    required this.nombre,
    required this.tipo,
  });
}