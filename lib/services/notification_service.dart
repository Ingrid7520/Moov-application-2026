// lib/services/notification_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import 'user_service.dart';

const String baseUrl = 'http://192.168.1.161:8001/api';

/// Service de notifications personnalisé (sans Firebase)
/// Utilise polling + notifications locales natives
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  Timer? _pollingTimer;
  int _unreadCount = 0;
  Set<String> _shownNotificationIds = {};

  int get unreadCount => _unreadCount;
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  bool _isInitialized = false;

  /// Initialiser le service de notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialiser notifications locales
      await _initializeLocalNotifications();

      // Charger les IDs déjà affichées
      await _loadShownNotificationIds();

      // Charger compteur initial
      await refreshUnreadCount();

      // Démarrer le polling (vérification toutes les 30 secondes)
      _startPolling();

      _isInitialized = true;
      print('✅ NotificationService initialisé (mode personnalisé)');
    } catch (e) {
      print('❌ Erreur initialisation notifications: $e');
    }
  }

  /// Initialiser les notifications locales
  Future<void> _initializeLocalNotifications() async {
    // Configuration Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuration iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialiser
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Demander permissions
    await _requestPermissions();

    // Créer canal Android (obligatoire Android 8+)
    const androidChannel = AndroidNotificationChannel(
      'agrismart_notifications',
      'AgriSmart Notifications',
      description: 'Notifications de l\'application AgriSmart CI',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    print('✅ Notifications locales initialisées');
  }

  /// Demander permissions
  Future<void> _requestPermissions() async {
    // Android 13+ (API 33+)
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      print(granted == true
          ? '✅ Permissions notifications accordées (Android)'
          : '⚠️ Permissions notifications refusées (Android)');
    }

    // iOS
    final iosPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      print(granted == true
          ? '✅ Permissions notifications accordées (Android)'
          : '⚠️ Permissions notifications refusées (Android)');
    }
  }

  /// Charger les IDs de notifications déjà affichées
  Future<void> _loadShownNotificationIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList('shown_notification_ids') ?? [];
      _shownNotificationIds = Set<String>.from(ids);
      print('📋 ${_shownNotificationIds.length} notifications déjà affichées');
    } catch (e) {
      print('❌ Erreur chargement IDs: $e');
    }
  }

  /// Sauvegarder les IDs de notifications affichées
  Future<void> _saveShownNotificationIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'shown_notification_ids',
        _shownNotificationIds.toList(),
      );
    } catch (e) {
      print('❌ Erreur sauvegarde IDs: $e');
    }
  }

  /// Démarrer le polling
  void _startPolling() {
    // Arrêter timer existant
    _pollingTimer?.cancel();

    // Créer nouveau timer (toutes les 30 secondes)
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) => _checkNewNotifications(),
    );

    // Vérifier immédiatement
    _checkNewNotifications();

    print('🔄 Polling démarré (toutes les 30s)');
  }

  /// Arrêter le polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    print('⏸️ Polling arrêté');
  }

  /// Vérifier les nouvelles notifications
  Future<void> _checkNewNotifications() async {
    try {
      // Récupérer les notifications non lues
      final notifications = await getNotifications(unreadOnly: true, limit: 10);

      // Filtrer les nouvelles (pas encore affichées)
      final newNotifications = notifications.where((n) {
        return !_shownNotificationIds.contains(n.id);
      }).toList();

      if (newNotifications.isEmpty) return;

      print('🔔 ${newNotifications.length} nouvelle(s) notification(s)');

      // Afficher chaque nouvelle notification
      for (var notification in newNotifications) {
        await _showLocalNotification(notification);
        _shownNotificationIds.add(notification.id);
      }

      // Sauvegarder les IDs
      await _saveShownNotificationIds();

      // Rafraîchir compteur
      await refreshUnreadCount();
    } catch (e) {
      print('❌ Erreur check notifications: $e');
    }
  }

  /// Afficher notification locale
  Future<void> _showLocalNotification(NotificationModel notification) async {
    try {
      // Configuration Android
      final androidDetails = AndroidNotificationDetails(
        'agrismart_notifications',
        'AgriSmart Notifications',
        channelDescription: 'Notifications de l\'application AgriSmart CI',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF4CAF50),
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(
          notification.body,
          contentTitle: notification.title,
          summaryText: 'AgriSmart CI',
        ),
      );

      // Configuration iOS
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Afficher
      await _localNotifications.show(
        notification.id.hashCode, // ID unique basé sur notification ID
        notification.title,
        notification.body,
        details,
        payload: json.encode({
          'notification_id': notification.id,
          'type': notification.notificationType,
          'action_url': notification.actionUrl,
        }),
      );

      print('🔔 Notification affichée: ${notification.title}');
    } catch (e) {
      print('❌ Erreur affichage notification: $e');
    }
  }

  /// Callback quand notification est tappée
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload == null) return;

    try {
      final data = json.decode(response.payload!);
      final notificationId = data['notification_id'] as String?;
      final actionUrl = data['action_url'] as String?;

      print('👆 Notification tappée: ID=$notificationId, URL=$actionUrl');

      // Marquer comme lue
      if (notificationId != null) {
        markAsRead(notificationId);
      }

      // TODO: Navigation vers l'écran approprié
      // if (actionUrl != null) { ... }
    } catch (e) {
      print('❌ Erreur tap notification: $e');
    }
  }

  // ========================================================================
  // API Notifications
  // ========================================================================

  /// Récupérer les notifications
  Future<List<NotificationModel>> getNotifications({
    bool unreadOnly = false,
    int limit = 50,
    int skip = 0,
  }) async {
    try {
      final token = await UserService.getToken();
      if (token == null) return [];

      final uri = Uri.parse('$baseUrl/notifications').replace(
        queryParameters: {
          'unread_only': unreadOnly.toString(),
          'limit': limit.toString(),
          'skip': skip.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((n) => NotificationModel.fromJson(n)).toList();
      }

      return [];
    } catch (e) {
      print('❌ Erreur get notifications: $e');
      return [];
    }
  }

  /// Récupérer compteur non lues
  Future<int> getUnreadCount() async {
    try {
      final token = await UserService.getToken();
      if (token == null) return 0;

      final response = await http.get(
        Uri.parse('$baseUrl/notifications/unread-count'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] as int;
      }
      return 0;
    } catch (e) {
      print('❌ Erreur unread count: $e');
      return 0;
    }
  }

  /// Rafraîchir compteur non lues
  Future<void> refreshUnreadCount() async {
    _unreadCount = await getUnreadCount();
    unreadCountNotifier.value = _unreadCount;
  }

  /// Marquer notification comme lue
  Future<bool> markAsRead(String notificationId) async {
    try {
      final token = await UserService.getToken();
      if (token == null) return false;

      final response = await http.patch(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        // Décrémenter compteur
        if (_unreadCount > 0) {
          _unreadCount--;
          unreadCountNotifier.value = _unreadCount;
        }
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Erreur mark as read: $e');
      return false;
    }
  }

  /// Marquer toutes comme lues
  Future<bool> markAllAsRead() async {
    try {
      final token = await UserService.getToken();
      if (token == null) return false;

      final response = await http.patch(
        Uri.parse('$baseUrl/notifications/read-all'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _unreadCount = 0;
        unreadCountNotifier.value = 0;
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Erreur mark all as read: $e');
      return false;
    }
  }

  /// Supprimer notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final token = await UserService.getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/$notificationId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 204) {
        // Retirer des IDs affichées
        _shownNotificationIds.remove(notificationId);
        await _saveShownNotificationIds();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Erreur delete notification: $e');
      return false;
    }
  }

  /// Obtenir statistiques
  Future<NotificationStats?> getStats() async {
    try {
      final token = await UserService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/notifications/stats'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return NotificationStats.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('❌ Erreur stats: $e');
      return null;
    }
  }

  /// Nettoyer (appelé au logout)
  Future<void> cleanup() async {
    stopPolling();
    _shownNotificationIds.clear();
    await _saveShownNotificationIds();
    _unreadCount = 0;
    unreadCountNotifier.value = 0;
    _isInitialized = false;
    print('🧹 NotificationService nettoyé');
  }

  /// Forcer vérification immédiate
  Future<void> forceCheck() async {
    await _checkNewNotifications();
  }
}