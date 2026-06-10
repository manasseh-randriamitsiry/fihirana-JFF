import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fihirana/features/auth/domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.displayName,
    super.photoURL,
    required super.emailVerified,
    super.canAddSongs,
    super.isAdmin,
    super.isSuperAdmin,
    super.addedHymnsCount,
    super.monthlyHymnCount,
    super.lastHymnAdditionMonth,
    required super.createdAt,
    required super.lastLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String uid) {
    return UserModel(
      id: uid,
      email: json['email'] ?? '',
      displayName: json['displayName'],
      photoURL: json['photoURL'],
      emailVerified: json['emailVerified'] ?? false,
      canAddSongs: json['canAddSongs'] ?? false,
      isAdmin: json['isAdmin'] ?? false,
      isSuperAdmin: json['isSuperAdmin'] ?? false,
      addedHymnsCount: json['addedHymnsCount'] ?? 0,
      monthlyHymnCount: json['monthlyHymnCount'] ?? 0,
      lastHymnAdditionMonth: json['lastHymnAdditionMonth'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (json['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
      emailVerified: user.emailVerified,
      canAddSongs: user.canAddSongs,
      isAdmin: user.isAdmin,
      isSuperAdmin: user.isSuperAdmin,
      addedHymnsCount: user.addedHymnsCount,
      monthlyHymnCount: user.monthlyHymnCount,
      lastHymnAdditionMonth: user.lastHymnAdditionMonth,
      createdAt: user.createdAt,
      lastLogin: user.lastLogin,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'emailVerified': emailVerified,
      'canAddSongs': canAddSongs,
      'isAdmin': isAdmin,
      'isSuperAdmin': isSuperAdmin,
      'addedHymnsCount': addedHymnsCount,
      'monthlyHymnCount': monthlyHymnCount,
      'lastHymnAdditionMonth': lastHymnAdditionMonth,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
    };
  }

  User toEntity() {
    return User(
      id: id,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
      emailVerified: emailVerified,
      canAddSongs: canAddSongs,
      isAdmin: isAdmin,
      isSuperAdmin: isSuperAdmin,
      addedHymnsCount: addedHymnsCount,
      monthlyHymnCount: monthlyHymnCount,
      lastHymnAdditionMonth: lastHymnAdditionMonth,
      createdAt: createdAt,
      lastLogin: lastLogin,
    );
  }
}
