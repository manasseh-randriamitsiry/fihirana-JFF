import 'package:fihirana/features/hymn/domain/entities/favorite.dart';

class FavoriteModel extends Favorite {
  FavoriteModel({
    required super.id,
    required super.hymnId,
    required super.userId,
    required super.userEmail,
    required super.addedDate,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['id']?.toString() ?? '',
      hymnId: json['hymnId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userEmail: json['userEmail']?.toString() ?? '',
      addedDate: DateTime.tryParse(json['addedDate'].toString()) ?? DateTime.now(),
    );
  }

  factory FavoriteModel.fromEntity(Favorite favorite) {
    return FavoriteModel(
      id: favorite.id,
      hymnId: favorite.hymnId,
      userId: favorite.userId,
      userEmail: favorite.userEmail,
      addedDate: favorite.addedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hymnId': hymnId,
      'userId': userId,
      'userEmail': userEmail,
      'addedDate': addedDate.toIso8601String(),
    };
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