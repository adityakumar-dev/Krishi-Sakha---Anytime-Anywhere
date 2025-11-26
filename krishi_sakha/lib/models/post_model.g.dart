// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PostModelAdapter extends TypeAdapter<PostModel> {
  @override
  final int typeId = 10;

  @override
  PostModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PostModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      type: fields[2] as String,
      content: fields[3] as String,
      imageUrl: fields[4] as String?,
      imageBase64: fields[5] as String?,
      status: fields[6] as String,
      placeId: fields[7] as String,
      cityName: fields[8] as String,
      stateName: fields[9] as String,
      latitude: fields[10] as double,
      longitude: fields[11] as double,
      createdAt: fields[12] as DateTime,
      likeCount: fields[13] as int,
      endorsementCount: fields[14] as int,
      commentCount: fields[17] as int,
      authorName: fields[18] as String?,
      authorRole: fields[19] as String?,
      isLiked: fields[20] as bool,
      isEndorsed: fields[21] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PostModel obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.imageUrl)
      ..writeByte(5)
      ..write(obj.imageBase64)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.placeId)
      ..writeByte(8)
      ..write(obj.cityName)
      ..writeByte(9)
      ..write(obj.stateName)
      ..writeByte(10)
      ..write(obj.latitude)
      ..writeByte(11)
      ..write(obj.longitude)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.likeCount)
      ..writeByte(14)
      ..write(obj.endorsementCount)
      ..writeByte(17)
      ..write(obj.commentCount)
      ..writeByte(18)
      ..write(obj.authorName)
      ..writeByte(19)
      ..write(obj.authorRole)
      ..writeByte(20)
      ..write(obj.isLiked)
      ..writeByte(21)
      ..write(obj.isEndorsed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
