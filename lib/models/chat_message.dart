import 'package:flutter/material.dart';

class ChatMessage {
  final String id;
  final String text;
  final DateTime timestamp;
  final bool isSentByMe;
  final String senderId;
  final MessageStatus status;
  final String? imageUrl;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.isSentByMe,
    required this.senderId,
    this.status = MessageStatus.sent,
    this.imageUrl,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isSentByMe: json['isSentByMe'] ?? false,
      senderId: json['senderId'] ?? '',
      status: MessageStatus.values.firstWhere(
        (status) => status.toString() == 'MessageStatus.${json['status'] ?? 'sent'}',
        orElse: () => MessageStatus.sent,
      ),
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isSentByMe': isSentByMe,
      'senderId': senderId,
      'status': status.toString().split('.').last,
      'imageUrl': imageUrl,
    };
  }

  // Format timestamp
  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Check if message was sent today
  bool get isToday {
    final now = DateTime.now();
    return timestamp.day == now.day &&
           timestamp.month == now.month &&
           timestamp.year == now.year;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}
