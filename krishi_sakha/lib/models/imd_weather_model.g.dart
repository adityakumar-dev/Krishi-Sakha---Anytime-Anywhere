// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'imd_weather_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ImdWeatherResponseAdapter extends TypeAdapter<ImdWeatherResponse> {
  @override
  final int typeId = 30;

  @override
  ImdWeatherResponse read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ImdWeatherResponse(
      station: fields[0] as String,
      lat: fields[1] as double,
      lon: fields[2] as double,
      sunrise: fields[3] as String,
      sunset: fields[4] as String,
      moonrise: fields[5] as String,
      moonset: fields[6] as String,
      forecastPeriod: (fields[7] as List).cast<ImdForecastDay>(),
      lastUpdated: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ImdWeatherResponse obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.station)
      ..writeByte(1)
      ..write(obj.lat)
      ..writeByte(2)
      ..write(obj.lon)
      ..writeByte(3)
      ..write(obj.sunrise)
      ..writeByte(4)
      ..write(obj.sunset)
      ..writeByte(5)
      ..write(obj.moonrise)
      ..writeByte(6)
      ..write(obj.moonset)
      ..writeByte(7)
      ..write(obj.forecastPeriod)
      ..writeByte(8)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImdWeatherResponseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ImdForecastDayAdapter extends TypeAdapter<ImdForecastDay> {
  @override
  final int typeId = 31;

  @override
  ImdForecastDay read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ImdForecastDay(
      dateOffset: fields[0] as int,
      date: fields[1] as String,
      max: fields[2] as double?,
      min: fields[3] as double?,
      desc: fields[4] as String,
      img: fields[5] as String,
      rh0830: fields[6] as int?,
      rh1730: fields[7] as int?,
      warning: fields[8] as String,
      warningColor: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ImdForecastDay obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.dateOffset)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.max)
      ..writeByte(3)
      ..write(obj.min)
      ..writeByte(4)
      ..write(obj.desc)
      ..writeByte(5)
      ..write(obj.img)
      ..writeByte(6)
      ..write(obj.rh0830)
      ..writeByte(7)
      ..write(obj.rh1730)
      ..writeByte(8)
      ..write(obj.warning)
      ..writeByte(9)
      ..write(obj.warningColor);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImdForecastDayAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
