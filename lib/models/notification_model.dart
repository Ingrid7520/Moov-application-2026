// lib/models/notification_model.dart
/// Modèle pour les notifications
/// Correspond au schéma backend NotificationResponse

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String notificationType;
  final String priority;
  final Map<String, dynamic> data;
  final String? imageUrl;
  final String? actionUrl;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.notificationType,
    required this.priority,
    required this.data,
    this.imageUrl,
    this.actionUrl,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  // Factory pour créer depuis JSON (API)
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      notificationType: json['notification_type'] as String,
      priority: json['priority'] as String,
      data: json['data'] as Map<String, dynamic>? ?? {},
      imageUrl: json['image_url'] as String?,
      actionUrl: json['action_url'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'notification_type': notificationType,
      'priority': priority,
      'data': data,
      'image_url': imageUrl,
      'action_url': actionUrl,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Copie avec modifications
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? notificationType,
    String? priority,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      notificationType: notificationType ?? this.notificationType,
      priority: priority ?? this.priority,
      data: data ?? this.data,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helpers pour le type de notification
  bool get isDiagnosticCompleted => notificationType == 'diagnostic_completed';
  bool get isPaymentSuccess => notificationType == 'payment_success';
  bool get isProductSold => notificationType == 'product_sold';
  bool get isSystemAlert => notificationType == 'system_alert';

  // Helper pour la priorité
  bool get isHighPriority => priority == 'high' || priority == 'urgent';

  // Icône selon le type
  String get iconEmoji {
    switch (notificationType) {
      case 'diagnostic_completed':
        return '🔬';
      case 'payment_success':
        return '💰';
      case 'payment_failed':
        return '❌';
      case 'product_sold':
        return '🎉';
      case 'product_purchased':
        return '🛒';
      case 'order_confirmed':
        return '✅';
      case 'message_received':
        return '💬';
      case 'system_alert':
        return '⚠️';
      default:
        return '📬';
    }
  }

  // Temps écoulé depuis création
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, isRead: $isRead)';
  }
}

/// Statistiques des notifications
class NotificationStats {
  final int total;
  final int unread;
  final Map<String, int> byType;

  NotificationStats({
    required this.total,
    required this.unread,
    required this.byType,
  });

  factory NotificationStats.fromJson(Map<String, dynamic> json) {
    return NotificationStats(
      total: json['total'] as int? ?? 0,
      unread: json['unread'] as int? ?? 0,
      byType: Map<String, int>.from(json['by_type'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'unread': unread,
      'by_type': byType,
    };
  }
}