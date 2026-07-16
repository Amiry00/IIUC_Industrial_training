import 'package:flutter/foundation.dart';

class AppNotification {
  final int id;
  final String title;
  final String body;
  final String type; // 'alert', 'reminder', 'favorite', 'system'
  final bool isRead;
  final DateTime timestamp;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.timestamp,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as int,
      title: map['title'] as String,
      body: map['body'] as String,
      type: map['type'] as String,
      isRead: (map['is_read'] as int) == 1,
      timestamp: DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'is_read': isRead ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  AppNotification copyWith({
    int? id,
    String? title,
    String? body,
    String? type,
    bool? isRead,
    DateTime? timestamp,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
