// screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'weather_detail_screen.dart'; // ← Import de la nouvelle page détaillée
import '../widgets/common_widgets.dart';
import '../widgets/quick_action_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? weatherData;
  bool isLoading = true;
  String errorMessage = '';

  // Ville par défaut – tu pourras la rendre dynamique plus tard
  final String cityName = "Aboisso";

  @override
  void initState() {
    super.initState();
    fetchWeatherByCity();
  }

  Future<void> fetchWeatherByCity() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    print('🚀 Tentative de requête vers http://192.168.137.239:8000/api/weather/city/');
    print('Body envoyé : ${json.encode({'city': cityName})}');

    try {
      final response = await http.post(
        Uri.parse('http://192.168.137.239:8000/api/weather/city/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'city': cityName}),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        setState(() {
          weatherData = jsonData;
          isLoading = false;
        });
      } else if (response.statusCode == 404) {
        throw Exception('Ville non trouvée');
      } else {
        throw Exception('Erreur serveur (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Erreur détaillée : $e');
      print('Type de l\'erreur : ${e.runtimeType}');
      if (e is http.ClientException) {
        print('ClientException message: ${e.message}');
      }

      setState(() {
        isLoading = false;
        errorMessage = 'Impossible de charger la météo :\n$e';
      });
    }
  }

  // Icône selon le code OpenWeatherMap
  IconData getWeatherIcon(String? iconCode) {
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
    final locationName = weatherData?['location']?['name'] ?? cityName;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Bonjour, Emmanuel",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Bienvenue sur AgriSmart CI",
                            style: TextStyle(color: Colors.green[100]),
                          ),
                        ],
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
                            builder: (context) => WeatherDetailScreen(weatherData: weatherData!),
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
                              ? Column(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.white, size: 40),
                                    const SizedBox(height: 8),
                                    Text(
                                      errorMessage,
                                      style: const TextStyle(color: Colors.white70),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: fetchWeatherByCity,
                                      child: const Text(
                                        "Réessayer",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          getWeatherIcon(current?['icon']),
                                          color: Colors.white,
                                          size: 50,
                                        ),
                                        const SizedBox(width: 16),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${current?['temperature'] ?? '--'}°C",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 36,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "$locationName, ${current?['description'] ?? 'Inconnu'}",
                                              style: TextStyle(color: Colors.green[100]),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          "Humidité",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        Text(
                                          "${current?['humidity'] ?? '--'}%",
                                          style: TextStyle(
                                            color: Colors.green[100],
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
                  const Text("Actions rapides",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.95,
                    children: [
                      QuickActionCard(
                        icon: Icons.camera_alt,
                        title: "Diagnostic",
                        subtitle: "Scanner une plante",
                        color: Colors.blue,
                        onTap: () {},
                      ),
                      QuickActionCard(
                        icon: Icons.trending_up,
                        title: "Prix marché",
                        subtitle: "Voir les cours",
                        color: Colors.green,
                        onTap: () {},
                      ),
                      const QuickActionCard(
                        icon: Icons.inventory,
                        title: "Mes produits",
                        subtitle: "Gérer l'inventaire",
                        color: Colors.purple,
                      ),
                      const QuickActionCard(
                        icon: Icons.attach_money,
                        title: "Transactions",
                        subtitle: "Historique",
                        color: Colors.orange,
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
                  const Text("Cette semaine",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
    );
  }
}