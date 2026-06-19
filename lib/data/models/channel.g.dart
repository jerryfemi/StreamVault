// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChannelAdapter extends TypeAdapter<Channel> {
  @override
  final typeId = 0;

  @override
  Channel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Channel(
      id: fields[0] as String,
      name: fields[1] as String,
      logo: fields[2] as String,
      streamUrl: fields[3] as String,
      category: fields[4] as String,
      tvgId: fields[5] as String,
      headers: fields[6] == null
          ? const {}
          : (fields[6] as Map).cast<String, String>(),
      quality: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Channel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.logo)
      ..writeByte(3)
      ..write(obj.streamUrl)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.tvgId)
      ..writeByte(6)
      ..write(obj.headers)
      ..writeByte(7)
      ..write(obj.quality);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChannelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
