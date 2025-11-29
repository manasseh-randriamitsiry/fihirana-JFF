import 'dart:convert';
import 'package:flutter/foundation.dart';

class UserRecording {
  final String id;
  final String hymnId;
  final String title;
  final String filePath;
  final int durationSeconds;
  final DateTime createdAt;
  final bool isPublic;
  final String? driveFileId;
  final String? driveWebLink;
  final String? publicLink;
  final String? userName;
  final String? userId;
  final String? userEmail;
  final String? userPhotoUrl;
  final List<String> tags;

  UserRecording({
    required this.id,
    required this.hymnId,
    required this.title,
    required this.filePath,
    required this.durationSeconds,
    required this.createdAt,
    this.isPublic = false,
    this.driveFileId,
    this.driveWebLink,
    this.publicLink,
    this.userName,
    this.userId,
    this.userEmail,
    this.userPhotoUrl,
    this.tags = const [],
  });

  UserRecording copyWith({
    String? id,
    String? hymnId,
    String? title,
    String? filePath,
    int? durationSeconds,
    DateTime? createdAt,
    bool? isPublic,
    String? driveFileId,
    String? driveWebLink,
    String? publicLink,
    String? userName,
    String? userId,
    String? userEmail,
    String? userPhotoUrl,
    List<String>? tags,
  }) {
    return UserRecording(
      id: id ?? this.id,
      hymnId: hymnId ?? this.hymnId,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAt: createdAt ?? this.createdAt,
      isPublic: isPublic ?? this.isPublic,
      driveFileId: driveFileId ?? this.driveFileId,
      driveWebLink: driveWebLink ?? this.driveWebLink,
      publicLink: publicLink ?? this.publicLink,
      userName: userName ?? this.userName,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hymnId': hymnId,
      'title': title,
      'filePath': filePath,
      'durationSeconds': durationSeconds,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isPublic': isPublic,
      'driveFileId': driveFileId,
      'driveWebLink': driveWebLink,
      'publicLink': publicLink,
      'userName': userName,
      'userId': userId,
      'userEmail': userEmail,
      'userPhotoUrl': userPhotoUrl,
      'tags': tags,
    };
  }

factory UserRecording.fromMap(Map<String, dynamic> map) {
    // Handle different possible field names for duration
    int duration = 0;
    if (map.containsKey('durationSeconds')) {
      duration = map['durationSeconds']?.toInt() ?? 0;
    } else if (map.containsKey('duration')) {
      duration = map['duration']?.toInt() ?? 0;
    }
    
    if (kDebugMode) {
      print('UserRecording.fromMap: Loaded recording with duration: $duration seconds from map');
    }
    
    return UserRecording(
      id: map['id'] ?? '',
      hymnId: map['hymnId'] ?? '',
      title: map['title'] ?? '',
      filePath: map['filePath'] ?? '',
      durationSeconds: duration,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      isPublic: map['isPublic'] ?? false,
      driveFileId: map['driveFileId'],
      driveWebLink: map['driveWebLink'],
      publicLink: map['publicLink'],
      userName: map['userName'],
      userId: map['userId'],
      userEmail: map['userEmail'],
      userPhotoUrl: map['userPhotoUrl'],
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  String toJson() => json.encode(toMap());

  factory UserRecording.fromJson(String source) =>
      UserRecording.fromMap(json.decode(source));
}
