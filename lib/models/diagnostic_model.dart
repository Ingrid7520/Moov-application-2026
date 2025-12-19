// lib/models/diagnostic_model.dart
/// Modèle pour les diagnostics
/// Correspond au schéma backend DiagnosticResponse

class DiagnosticModel {
  final String id;
  final String userId;
  final String userName;
  final String imagePath;
  final String imageUrl;
  final String? plantName;
  final String? diseaseName;
  final String? severity;
  final double? confidence;
  final String? description;
  final List<String> symptoms;
  final List<String> treatments;
  final List<String> preventionTips;
  final String? notes;
  final String status;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;

  DiagnosticModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.imagePath,
    required this.imageUrl,
    this.plantName,
    this.diseaseName,
    this.severity,
    this.confidence,
    this.description,
    required this.symptoms,
    required this.treatments,
    required this.preventionTips,
    this.notes,
    required this.status,
    this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory depuis JSON
  factory DiagnosticModel.fromJson(Map<String, dynamic> json) {
    return DiagnosticModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String? ?? 'Utilisateur',
      imagePath: json['image_path'] as String,
      imageUrl: json['image_url'] as String,
      plantName: json['plant_name'] as String?,
      diseaseName: json['disease_name'] as String?,
      severity: json['severity'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      description: json['description'] as String?,
      symptoms: List<String>.from(json['symptoms'] as List? ?? []),
      treatments: List<String>.from(json['treatments'] as List? ?? []),
      preventionTips: List<String>.from(json['prevention_tips'] as List? ?? []),
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'completed',
      location: json['location'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'image_path': imagePath,
      'image_url': imageUrl,
      'plant_name': plantName,
      'disease_name': diseaseName,
      'severity': severity,
      'confidence': confidence,
      'description': description,
      'symptoms': symptoms,
      'treatments': treatments,
      'prevention_tips': preventionTips,
      'notes': notes,
      'status': status,
      'location': location,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Copie avec modifications
  DiagnosticModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? imagePath,
    String? imageUrl,
    String? plantName,
    String? diseaseName,
    String? severity,
    double? confidence,
    String? description,
    List<String>? symptoms,
    List<String>? treatments,
    List<String>? preventionTips,
    String? notes,
    String? status,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiagnosticModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      plantName: plantName ?? this.plantName,
      diseaseName: diseaseName ?? this.diseaseName,
      severity: severity ?? this.severity,
      confidence: confidence ?? this.confidence,
      description: description ?? this.description,
      symptoms: symptoms ?? this.symptoms,
      treatments: treatments ?? this.treatments,
      preventionTips: preventionTips ?? this.preventionTips,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helpers pour la sévérité
  bool get hasDisease => diseaseName != null &&
      diseaseName!.isNotEmpty &&
      diseaseName!.toLowerCase() != 'aucune';

  String get severityLabel {
    switch (severity) {
      case 'none':
        return 'Aucune';
      case 'low':
        return 'Faible';
      case 'moderate':
        return 'Modérée';
      case 'high':
        return 'Élevée';
      case 'critical':
        return 'Critique';
      default:
        return 'Inconnue';
    }
  }

  // Couleur selon la sévérité
  int get severityColor {
    switch (severity) {
      case 'none':
        return 0xFF4CAF50; // Vert
      case 'low':
        return 0xFF8BC34A; // Vert clair
      case 'moderate':
        return 0xFFFF9800; // Orange
      case 'high':
        return 0xFFFF5722; // Orange foncé
      case 'critical':
        return 0xFFF44336; // Rouge
      default:
        return 0xFF9E9E9E; // Gris
    }
  }

  // Emoji selon sévérité
  String get severityEmoji {
    switch (severity) {
      case 'none':
        return '✅';
      case 'low':
        return '⚠️';
      case 'moderate':
        return '🔶';
      case 'high':
        return '🔴';
      case 'critical':
        return '🚨';
      default:
        return '❓';
    }
  }

  // Helper pour le statut
  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isFailed => status == 'failed';

  // Temps écoulé
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

  // Confiance en pourcentage formaté
  String get confidencePercentage {
    if (confidence == null) return 'N/A';
    return '${confidence!.toStringAsFixed(1)}%';
  }

  @override
  String toString() {
    return 'DiagnosticModel(id: $id, plant: $plantName, disease: $diseaseName)';
  }
}

/// Statistiques des diagnostics
class DiagnosticStats {
  final int total;
  final Map<String, int> byStatus;
  final Map<String, int> bySeverity;
  final List<CommonDisease> mostCommonDiseases;
  final int recentDiagnostics;

  DiagnosticStats({
    required this.total,
    required this.byStatus,
    required this.bySeverity,
    required this.mostCommonDiseases,
    required this.recentDiagnostics,
  });

  factory DiagnosticStats.fromJson(Map<String, dynamic> json) {
    return DiagnosticStats(
      total: json['total'] as int? ?? 0,
      byStatus: Map<String, int>.from(json['by_status'] as Map? ?? {}),
      bySeverity: Map<String, int>.from(json['by_severity'] as Map? ?? {}),
      mostCommonDiseases: (json['most_common_diseases'] as List?)
          ?.map((e) => CommonDisease.fromJson(e))
          .toList() ??
          [],
      recentDiagnostics: json['recent_diagnostics'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'by_status': byStatus,
      'by_severity': bySeverity,
      'most_common_diseases': mostCommonDiseases.map((d) => d.toJson()).toList(),
      'recent_diagnostics': recentDiagnostics,
    };
  }
}

/// Maladie commune avec statistiques
class CommonDisease {
  final String diseaseName;
  final int count;
  final double avgSeverity;

  CommonDisease({
    required this.diseaseName,
    required this.count,
    required this.avgSeverity,
  });

  factory CommonDisease.fromJson(Map<String, dynamic> json) {
    return CommonDisease(
      diseaseName: json['disease_name'] as String,
      count: json['count'] as int,
      avgSeverity: (json['avg_severity'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'disease_name': diseaseName,
      'count': count,
      'avg_severity': avgSeverity,
    };
  }
}