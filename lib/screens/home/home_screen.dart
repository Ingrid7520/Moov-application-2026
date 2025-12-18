// lib/screens/home/home_screen.dart
// ✅ Utilise l'API météo Django existante (port 8000)

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'weather_detail_screen.dart';
import '../diagnostic/diagnostic_screen.dart';
import '../market/market_screen.dart';
import '../products/my_products_screen.dart';
import '../marketplace/my_purchases_screen.dart';
import '../../services/user_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/quick_action_card.dart';

// ✅ API Django sur port 8000
const String djangoBaseUrl = 'http://10.0.2.2:8000/api';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? weatherData;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserAndWeather();
  }

  Future<void> _loadUserAndWeather() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // 1. Charger les données utilisateur
      userData = await UserService.getUserData();

      // 2. Charger la météo selon la ville de l'utilisateur
      await _fetchWeatherForUserCity();

    } catch (e) {
      setState(() {
        errorMessage = 'Erreur de chargement';
        isLoading = false;
      });
      print('❌ Erreur: $e');
    }
  }

  Future<void> _fetchWeatherForUserCity() async {
    try {
      // Récupérer la ville de l'utilisateur
      final city = userData?['location'] ??
          userData?['region'] ??
          'Abidjan';

      print('🌤️ Météo demandée pour: $city');

      // ✅ Appel à l'API météo Django existante
      final response = await http.post(
        Uri.parse('$djangoBaseUrl/weather/city/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'city': city}),
      ).timeout(const Duration(seconds: 15));

      print('📡 Météo Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        if (mounted) {
          setState(() {
            weatherData = data;
            isLoading = false;
          });
        }
      } else if (response.statusCode == 404) {
        throw Exception('Ville non trouvée');
      } else {
        throw Exception('Erreur serveur (${response.statusCode})');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Météo indisponible';
        });
      }
      print('❌ Erreur météo: $e');
    }
  }

  IconData _getWeatherIcon(String? iconCode) {
    if (iconCode == null) return Icons.cloud;
    if (iconCode.startsWith('01')) return Icons.wb_sunny;
    if (iconCode.startsWith('02')) return Icons.wb_cloudy;
    if (iconCode.startsWith('03') || iconCode.startsWith('04')) return Icons.cloud;
    if (iconCode.startsWith('09') || iconCode.startsWith('10')) return Icons.grain;
    if (iconCode.startsWith('11')) return Icons.flash_on;
    if (iconCode.startsWith('13')) return Icons.ac_unit;
    if (iconCode.startsWith('50')) return Icons.compare_arrows;
    return Icons.cloud;
  }

  @override
  Widget build(BuildContext context) {
    final current = weatherData?['current'];
    final locationName = weatherData?['location']?['name'] ??
        userData?['location'] ??
        'Votre ville';
    final userName = userData?['name'] ?? 'Utilisateur';

    return SafeArea(
      top: false,
      child: RefreshIndicator(
        onRefresh: _loadUserAndWeather,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // === En-tête avec dégradé ===
              Container(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[600]!, Colors.green[700]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    // En-tête avec nom
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Bonjour, $userName",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Bienvenue sur AgriSmart CI",
                                style: TextStyle(color: Colors.green[100]),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications, color: Colors.white),
                        )
                      ],
                    ),
                    const SizedBox(height: 24),

                    // === Zone Météo CLIQUABLE ===
                    InkWell(
                      onTap: () {
                        if (weatherData != null && !isLoading && errorMessage.isEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WeatherDetailScreen(
                                  weatherData: weatherData!
                              ),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: isLoading
                            ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                            : errorMessage.isNotEmpty
                            ? _buildWeatherError()
                            : _buildWeatherContent(current, locationName),
                      ),
                    ),
                  ],
                ),
              ),

              // === Actions rapides ===
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Actions rapides",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.95,
                      children: [
                        // Diagnostic
                        QuickActionCard(
                          icon: Icons.camera_alt,
                          title: "Diagnostic",
                          subtitle: "Scanner une plante",
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DiagnosticScreen(),
                              ),
                            );
                          },
                        ),

                        // Prix marché
                        QuickActionCard(
                          icon: Icons.trending_up,
                          title: "Prix marché",
                          subtitle: "Voir les cours",
                          color: Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MarketScreen(),
                              ),
                            );
                          },
                        ),

                        // Mes produits
                        QuickActionCard(
                          icon: Icons.inventory,
                          title: "Mes produits",
                          subtitle: "Gérer l'inventaire",
                          color: Colors.purple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyProductsScreen(),
                              ),
                            );
                          },
                        ),

                        // Transactions
                        QuickActionCard(
                          icon: Icons.attach_money,
                          title: "Mes achats",
                          subtitle: "Historique",
                          color: Colors.orange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyPurchasesScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // === Statistiques de la semaine ===
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Cette semaine",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          StatItem(label: "Diagnostics", value: "12"),
                          SizedBox(height: 40, child: VerticalDivider()),
                          StatItem(label: "Ventes", value: "45K"),
                          SizedBox(height: 40, child: VerticalDivider()),
                          StatItem(label: "Alertes", value: "3"),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherContent(dynamic current, String locationName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(
                _getWeatherIcon(current?['icon']),
                color: Colors.white,
                size: 45,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "${current?['temperature'] ?? '--'}°C",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      "$locationName, ${current?['description'] ?? 'Inconnu'}",
                      style: TextStyle(color: Colors.green[100], fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              "Humidité",
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            Text(
              "${current?['humidity'] ?? '--'}%",
              style: TextStyle(
                color: Colors.green[100],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeatherError() {
    return Column(
      children: [
        const Icon(Icons.cloud_off, color: Colors.white, size: 30),
        const SizedBox(height: 4),
        const Text(
          "Météo indisponible",
          style: TextStyle(color: Colors.white),
        ),
        TextButton(
          onPressed: _loadUserAndWeather,
          child: const Text(
            "Réessayer",
            style: TextStyle(
              color: Colors.white,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}