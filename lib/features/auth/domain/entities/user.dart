import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final bool emailVerified;
  final bool canAddSongs;
  final bool isAdmin;
  final bool isSuperAdmin;
  final int addedHymnsCount;
  final int monthlyHymnCount;
  final String lastHymnAdditionMonth;
  final DateTime createdAt;
  final DateTime lastLogin;

  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.emailVerified,
    this.canAddSongs = false,
    this.isAdmin = false,
    this.isSuperAdmin = false,
    this.addedHymnsCount = 0,
    this.monthlyHymnCount = 0,
    this.lastHymnAdditionMonth = '',
    required this.createdAt,
    required this.lastLogin,
  });

  factory User.fromFirebaseUser(Map<String, dynamic> data, String uid) {
    return User(
      id: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      emailVerified: data['emailVerified'] ?? false,
      canAddSongs: data['canAddSongs'] ?? false,
      isAdmin: data['isAdmin'] ?? false,
      isSuperAdmin: data['isSuperAdmin'] ?? false,
      addedHymnsCount: data['addedHymnsCount'] ?? 0,
      monthlyHymnCount: data['monthlyHymnCount'] ?? 0,
      lastHymnAdditionMonth: data['lastHymnAdditionMonth'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
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

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    bool? emailVerified,
    bool? canAddSongs,
    bool? isAdmin,
    bool? isSuperAdmin,
    int? addedHymnsCount,
    int? monthlyHymnCount,
    String? lastHymnAdditionMonth,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      emailVerified: emailVerified ?? this.emailVerified,
      canAddSongs: canAddSongs ?? this.canAddSongs,
      isAdmin: isAdmin ?? this.isAdmin,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      addedHymnsCount: addedHymnsCount ?? this.addedHymnsCount,
      monthlyHymnCount: monthlyHymnCount ?? this.monthlyHymnCount,
      lastHymnAdditionMonth:
          lastHymnAdditionMonth ?? this.lastHymnAdditionMonth,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  int get effectiveMonthlyHymnCount {
    final currentMonth = DateTime.now().toString().substring(0, 7); // YYYY-MM
    if (lastHymnAdditionMonth != currentMonth) {
      return 0;
    }
    return monthlyHymnCount;
  }

  int get remainingHymnsThisMonth => 5 - effectiveMonthlyHymnCount;
}
