// lib/services/user_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

/// Service pour gérer les données utilisateur stockées localement
class UserService {
  static const _storage = FlutterSecureStorage();

  // Clés de stockage
  static const String _keyToken = 'jwt_token';
  static const String _keyUserData = 'user_data';

  /// Sauvegarder le token JWT
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  /// Récupérer le token JWT
  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  /// Sauvegarder les données utilisateur complètes
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final userJson = json.encode(userData);
    await _storage.write(key: _keyUserData, value: userJson);
  }

  /// Récupérer les données utilisateur
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final userJson = await _storage.read(key: _keyUserData);
      if (userJson != null) {
        return json.decode(userJson);
      }
      return null;
    } catch (e) {
      print("Erreur lors de la récupération des données utilisateur: $e");
      return null;
    }
  }

  /// Récupérer le type d'utilisateur (producer, buyer, both, admin)
  static Future<String?> getUserType() async {
    final userData = await getUserData();
    return userData?['user_type'];
  }

  /// Vérifier si l'utilisateur est producteur
  static Future<bool> isProducer() async {
    final userType = await getUserType();
    return userType == 'producer' || userType == 'both' || userType == 'admin';
  }

  /// Vérifier si l'utilisateur est acheteur
  static Future<bool> isBuyer() async {
    final userType = await getUserType();
    return userType == 'buyer' || userType == 'both' || userType == 'admin';
  }

  /// Déconnecter l'utilisateur (supprimer toutes les données)
  static Future<void> logout() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUserData);
  }

  /// Vérifier si l'utilisateur est connecté
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}