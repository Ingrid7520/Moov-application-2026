// lib/services/diagnostic_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/diagnostic_model.dart';
import 'user_service.dart';

const String baseUrl = 'http://192.168.1.161:8001/api';

/// Service de gestion des diagnostics
class DiagnosticService {
  static final DiagnosticService _instance = DiagnosticService._internal();
  factory DiagnosticService() => _instance;
  DiagnosticService._internal();

  /// Créer un diagnostic
  Future<DiagnosticModel?> createDiagnostic({
    required String imagePath,
    String? plantName,
    String? diseaseName,
    String? severity,
    double? confidence,
    String? description,
    List<String>? symptoms,
    List<String>? treatments,
    List<String>? preventionTips,
    String? notes,
    String? location,
  }) async {
    try {
      final token = await UserService.getToken();
      if (token == null) throw Exception('Non authentifié');

      final body = {
        'image_path': imagePath,
        if (plantName != null) 'plant_name': plantName,
        if (diseaseName != null) 'disease_name': diseaseName,
        if (severity != null) 'severity': severity,
        if (confidence != null) 'confidence': confidence,
        if (description != null) 'description': description,
        if (symptoms != null) 'symptoms': symptoms,
        if (treatments != null) 'treatments': treatments,
        if (preventionTips != null) 'prevention_tips': preventionTips,
        if (notes != null) 'notes': notes,
        if (location != null) 'location': location,
      };

      print('📤 Création diagnostic: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/diagnostics'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      print('📥 Réponse: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return DiagnosticModel.fromJson(data);
      }

      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    } catch (e) {
      print('❌ Erreur création diagnostic: $e');
      return null;
    }
  }

  /// Récupérer les diagnostics
  Future<List<DiagnosticModel>> getDiagnostics({
    String? status,
    String? severity,
    int limit = 50,
    int skip = 0,
  }) async {
    try {
      final token = await UserService.getToken();
      if (token == null) return [];

      final queryParams = <String, String>{
        'limit': limit.toString(),
        'skip': skip.toString(),
      };
      if (status != null) queryParams['status'] = status;
      if (severity != null) queryParams['severity'] = severity;

      final uri = Uri.parse('$baseUrl/diagnostics').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((d) => DiagnosticModel.fromJson(d)).toList();
      }

      return [];
    } catch (e) {
      print('❌ Erreur get diagnostics: $e');
      return [];
    }
  }

  /// Récupérer diagnostics récents
  Future<List<DiagnosticModel>> getRecentDiagnostics({int days = 7}) async {
    try {
      final token = await UserService.getToken();
      if (token == null) return [];

      final uri = Uri.parse('$baseUrl/diagnostics/recent').replace(
        queryParameters: {'days': days.toString()},
      );

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((d) => DiagnosticModel.fromJson(d)).toList();
      }

      return [];
    } catch (e) {
      print('❌ Erreur diagnostics récents: $e');
      return [];
    }
  }

  /// Récupérer un diagnostic par ID
  Future<DiagnosticModel?> getDiagnostic(String id) async {
    try {
      final token = await UserService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/diagnostics/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return DiagnosticModel.fromJson(json.decode(response.body));
      }

      return null;
    } catch (e) {
      print('❌ Erreur get diagnostic: $e');
      return null;
    }
  }

  /// Mettre à jour un diagnostic
  Future<DiagnosticModel?> updateDiagnostic(
      String id,
      Map<String, dynamic> updates,
      ) async {
    try {
      final token = await UserService.getToken();
      if (token == null) return null;

      final response = await http.put(
        Uri.parse('$baseUrl/diagnostics/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        return DiagnosticModel.fromJson(json.decode(response.body));
      }

      return null;
    } catch (e) {
      print('❌ Erreur update diagnostic: $e');
      return null;
    }
  }

  /// Supprimer un diagnostic
  Future<bool> deleteDiagnostic(String id) async {
    try {
      final token = await UserService.getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/diagnostics/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 204;
    } catch (e) {
      print('❌ Erreur delete diagnostic: $e');
      return false;
    }
  }

  /// Obtenir statistiques
  Future<DiagnosticStats?> getStats() async {
    try {
      final token = await UserService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/diagnostics/stats'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return DiagnosticStats.fromJson(json.decode(response.body));
      }

      return null;
    } catch (e) {
      print('❌ Erreur stats: $e');
      return null;
    }
  }
}