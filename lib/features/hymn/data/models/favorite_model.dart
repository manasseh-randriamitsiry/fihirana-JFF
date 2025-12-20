import 'package:fihirana/features/hymn/domain/entities/favorite.dart';
import 'package:json_annotation/json_annotation.dart';

part 'favorite_model.g.dart';

@JsonSerializable()
class FavoriteModel extends Favorite {
  FavoriteModel({
    required super.id,
    required super.hymnId,
    required super.userId,
    required super.userEmail,
    required super.addedDate,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) =>
      _$FavoriteModelFromJson(json);

  Map<String, dynamic> toJson() => _$FavoriteModelToJson(this);

  factory FavoriteModel.fromEntity(Favorite favorite) {
    return FavoriteModel(
      id: favorite.id,
      hymnId: favorite.hymnId,
      userId: favorite.userId,
      userEmail: favorite.userEmail,
      addedDate: favorite.addedDate,
    );
  }



  Favorite toEntity() {
    return Favorite(
      id: id,
      hymnId: hymnId,
      userId: userId,
      userEmail: userEmail,
      addedDate: addedDate,
    );
  }
}