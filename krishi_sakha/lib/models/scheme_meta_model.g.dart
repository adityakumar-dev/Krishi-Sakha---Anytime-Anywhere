// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheme_meta_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SchemeModelAdapter extends TypeAdapter<SchemeModel> {
  @override
  final int typeId = 20;

  @override
  SchemeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SchemeModel(
      sNo: fields[0] as int,
      id: fields[1] as String,
      highlight: (fields[2] as List?)?.cast<String>(),
      beneficiaryState: (fields[3] as List?)?.cast<String>(),
      schemeShortTitle: fields[4] as String?,
      level: fields[5] as String?,
      schemeFor: fields[6] as String?,
      schemeCategory: (fields[7] as List?)?.cast<String>(),
      schemeName: fields[8] as String,
      schemeCloseDate: fields[9] as DateTime?,
      priority: fields[10] as double?,
      slug: fields[11] as String,
      briefDescription: fields[12] as String?,
      tags: (fields[13] as List?)?.cast<String>(),
      nodalMinistryName: fields[14] as String?,
      uploadDate: fields[15] as DateTime,
      createdAt: fields[16] as DateTime?,
      updatedAt: fields[17] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SchemeModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.sNo)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(2)
      ..write(obj.highlight)
      ..writeByte(3)
      ..write(obj.beneficiaryState)
      ..writeByte(4)
      ..write(obj.schemeShortTitle)
      ..writeByte(5)
      ..write(obj.level)
      ..writeByte(6)
      ..write(obj.schemeFor)
      ..writeByte(7)
      ..write(obj.schemeCategory)
      ..writeByte(8)
      ..write(obj.schemeName)
      ..writeByte(9)
      ..write(obj.schemeCloseDate)
      ..writeByte(10)
      ..write(obj.priority)
      ..writeByte(11)
      ..write(obj.slug)
      ..writeByte(12)
      ..write(obj.briefDescription)
      ..writeByte(13)
      ..write(obj.tags)
      ..writeByte(14)
      ..write(obj.nodalMinistryName)
      ..writeByte(15)
      ..write(obj.uploadDate)
      ..writeByte(16)
      ..write(obj.createdAt)
      ..writeByte(17)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchemeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SchemeFilterModelAdapter extends TypeAdapter<SchemeFilterModel> {
  @override
  final int typeId = 21;

  @override
  SchemeFilterModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SchemeFilterModel(
      filterId: fields[0] as int,
      filterType: fields[1] as String,
      filterValue: fields[2] as String,
      createdAt: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SchemeFilterModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.filterId)
      ..writeByte(1)
      ..write(obj.filterType)
      ..writeByte(2)
      ..write(obj.filterValue)
      ..writeByte(3)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchemeFilterModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
