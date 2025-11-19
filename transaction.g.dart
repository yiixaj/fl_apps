// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 0;

  @override
  TransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionModel(
      id: fields[0] as String,
      tipo: fields[1] as String,
      monto: fields[2] as double,
      descripcion: fields[3] as String,
      categoriaId: fields[4] as String,
      metaId: fields[5] as String,
      fecha: fields[6] as DateTime,
      pendingSync: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tipo)
      ..writeByte(2)
      ..write(obj.monto)
      ..writeByte(3)
      ..write(obj.descripcion)
      ..writeByte(4)
      ..write(obj.categoriaId)
      ..writeByte(5)
      ..write(obj.metaId)
      ..writeByte(6)
      ..write(obj.fecha)
      ..writeByte(7)
      ..write(obj.pendingSync);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
