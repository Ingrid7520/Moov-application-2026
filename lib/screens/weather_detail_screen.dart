// screens/weather_detail_screen.dart

import 'package:flutter/material.dart';

class WeatherDetailScreen extends StatelessWidget {
  final Map<String, dynamic> weatherData;

  const WeatherDetailScreen({super.key, required this.weatherData});

  // Icône selon code OpenWeatherMap
  IconData getWeatherIcon(String? iconCode, {double size = 40}) {
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

  // Couleur selon sévérité de l'alerte
  Color getAlertColor(String severity) {
    switch (severity) {
      case 'high':
        return Colors.red.shade50;
      case 'medium':
        return Colors.orange.shade50;
      case 'low':
        return Colors.green.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  IconData getAlertIcon(String severity) {
    switch (severity) {
      case 'high':
        return Icons.warning_amber_rounded;
      case 'medium':
        return Icons.info_outline_rounded;
      case 'low':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = weatherData['current'];
    final forecast = weatherData['forecast'] as List<dynamic>;
    final alerts = weatherData['alerts'] as List<dynamic>;
    final location = weatherData['location'];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // === Header avec dégradé ===
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                location['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
                
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[700]!, Colors.green[900]!],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            getWeatherIcon(current['icon']),
                            color: Colors.white,
                            size: 100,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "${current['temperature']}°",
                            style: const TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            current['description'],
                            style: const TextStyle(fontSize: 20, color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Ressenti ${current['feels_like']}° • Max ${current['temp_max']}° • Min ${current['temp_min']}°",
                            style: const TextStyle(color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Conditions actuelles", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // === Grille des détails actuels ===
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _buildInfoCard("Humidité", "${current['humidity']}%", Icons.water_drop),
                      _buildInfoCard("Vent", "${current['wind_speed']} km/h", Icons.air),
                      _buildInfoCard("Pression", "${current['pressure']} hPa", Icons.speed),
                      _buildInfoCard("Visibilité", "${current['visibility']} km", Icons.visibility),
                      _buildInfoCard("Lever du soleil", current['sunrise'], Icons.wb_twighlight),
                      _buildInfoCard("Coucher du soleil", current['sunset'], Icons.nights_stay),
                    ],
                  ),

                  const SizedBox(height: 32),

                   // === Prévisions 5 jours ===
                  const Text("Prévisions sur 5 jours", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: forecast.length,
                      itemBuilder: (context, index) {
                        final day = forecast[index];
                        return _buildForecastCard(day);
                      },
                    ),
                  ),

                  const SizedBox(height: 40),

                  // === Alertes agricoles ===
                  if (alerts.isNotEmpty) ...[
                    const Text("Alertes agricoles", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ...alerts.map((alert) => _buildAlertCard(alert)).toList(),
                    const SizedBox(height: 32),
                  ] else ...[
                    _buildAlertCard({
                      "id": "optimal",
                      "type": "weather",
                      "severity": "low",
                      "icon": "✅",
                      "title": "Aucune alerte",
                      "message": "Conditions stables et favorables pour vos cultures.",
                      "recommendations": ["Tout va bien ! Continuez vos activités normalement."]
                    }),
                    const SizedBox(height: 32),
                  ],

                 
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.green[700], size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: getAlertColor(alert['severity']),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: getAlertColor(alert['severity']).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(getAlertIcon(alert['severity']), color: Colors.green[800]),
              const SizedBox(width: 8),
              Text(alert['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          const SizedBox(height: 8),
          Text(alert['message'], style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 12),
          ...alert['recommendations'].map<Widget>((rec) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(rec)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildForecastCard(Map<String, dynamic> day) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(day['day_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Icon(getWeatherIcon(day['icon']), size: 40, color: Colors.green[700]),
          Text("${day['temp'].toInt()}°", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text("↓ ${day['temp_min'].toInt()}° ↑ ${day['temp_max'].toInt()}°", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text("${day['rain_probability']}% 🌧", style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}