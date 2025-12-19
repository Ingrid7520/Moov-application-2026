// lib/services/user_service.dart
// ✅ COMPLET - Toutes les méthodes + getUserId() ajoutée

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String baseUrl = 'http://192.168.1.161:8001/api';

  // ✅ Vérifier si l'utilisateur est connecté
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Sauvegarder le token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
    print('✅ Token sauvegardé');
  }

  // Récupérer le token
  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // ✅ NOUVELLE MÉTHODE - Récupérer uniquement l'ID utilisateur
  static Future<String?> getUserId() async {
    final userId = await _storage.read(key: 'user_id');
    print('🔍 UserId récupéré: $userId');
    return userId;
  }

  // Sauvegarder les données utilisateur
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    // ✅ CORRECTION : Utiliser _id depuis MongoDB
    final userId = userData['_id'] ?? userData['id'];

    await _storage.write(key: 'user_id', value: userId);
    await _storage.write(key: 'user_name', value: userData['name']);
    await _storage.write(key: 'user_phone', value: userData['phone_number']);
    await _storage.write(key: 'user_type', value: userData['user_type']);
    await _storage.write(key: 'user_location', value: userData['location']);

    print('✅ UserData sauvegardé avec ID: $userId');
  }

  // ✅ Récupérer les données utilisateur avec l'ID correct
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final userId = await _storage.read(key: 'user_id');
      final name = await _storage.read(key: 'user_name');
      final phone = await _storage.read(key: 'user_phone');
      final userType = await _storage.read(key: 'user_type');
      final location = await _storage.read(key: 'user_location');

      if (userId == null) {
        print('❌ UserId null dans secure storage');
        return null;
      }

      print('✅ UserData récupéré - ID: $userId, Name: $name');

      return {
        '_id': userId,  // ✅ ID MongoDB (format backend)
        'id': userId,   // ✅ Aussi disponible comme 'id'
        'name': name,
        'phone_number': phone,
        'user_type': userType,
        'location': location,
      };
    } catch (e) {
      print('❌ Erreur getUserData: $e');
      return null;
    }
  }

  // Récupérer le profil depuis l'API
  static Future<Map<String, dynamic>?> fetchProfile() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        // ✅ Sauvegarder avec _id MongoDB
        await saveUserData(data);

        return data;
      }
      return null;
    } catch (e) {
      print('❌ Erreur fetchProfile: $e');
      return null;
    }
  }

  // Déconnexion
  static Future<void> logout() async {
    await _storage.deleteAll();
    print('✅ Déconnexion réussie');
  }
}