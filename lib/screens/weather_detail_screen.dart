// screens/weather_detail_screen.dart

import 'package:flutter/material.dart';

class WeatherDetailScreen extends StatefulWidget {
  final Map<String, dynamic> weatherData;

  const WeatherDetailScreen({super.key, required this.weatherData});

  @override
  State<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

class _WeatherDetailScreenState extends State<WeatherDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // Emojis météo précis et expressifs selon les codes OpenWeatherMap
  String getWeatherEmoji(String? iconCode) {
    if (iconCode == null) return '☁️';

    switch (iconCode) {
      case '01d':
        return '☀️'; // Soleil éclatant
      case '01n':
        return '🌙'; // Ciel clair nuit

      case '02d':
        return '🌤️'; // Soleil + quelques nuages
      case '02n':
        return '☁️'; // Quelques nuages nuit

      case '03d':
      case '03n':
        return '⛅'; // Nuages épars

      case '04d':
      case '04n':
        return '☁️'; // Ciel couvert

      case '09d':
      case '09n':
        return '🌧️'; // Averses / pluie légère

      case '10d':
        return '🌦️'; // Soleil + pluie
      case '10n':
        return '🌧️'; // Pluie la nuit

      case '11d':
      case '11n':
        return '⛈️'; // Orage

      case '13d':
      case '13n':
        return '❄️'; // Neige

      case '50d':
      case '50n':
        return '🌫️'; // Brouillard

      default:
        return '☁️';
    }
  }

  List<Color> getWeatherGradient(String? iconCode) {
  if (iconCode == null) {
    return [Colors.blue[400]!, Colors.blue[700]!];
  }

  final bool isNight = iconCode.endsWith('n');

  // Clair ciel (01d/01n)
  if (iconCode.startsWith('01')) {
    if (isNight) {
      return [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]; // Bleu nuit étoilé
    }
    return [const Color(0xFF87CEEB), const Color(0xFF00BFFF)]; // Ciel bleu clair → soleil visible
  }

  // Quelques nuages (02d/02n)
  if (iconCode.startsWith('02')) {
    if (isNight) {
      return [const Color(0xFF374151), const Color(0xFF1F2937)];
    }
    return [const Color(0xFFAED6F1), const Color(0xFF5DADE2)]; // Bleu clair avec nuages
  }

  // Nuages dispersés/scattered (03d/03n) ou couverts (04d/04n)
  if (iconCode.startsWith('03') || iconCode.startsWith('04')) {
    return [const Color(0xFFB0BEC5), const Color(0xFF78909C)]; // Gris clair → bon contraste pour tous emojis
  }

  // Pluie légère/drizzle (09d/09n) ou pluie (10d/10n)
  if (iconCode.startsWith('09') || iconCode.startsWith('10')) {
    if (isNight) {
      return [const Color(0xFF455A64), const Color(0xFF263238)];
    }
    return [const Color(0xFF90A4AE), const Color(0xFF607D8B)]; // Gris-bleu moyen → pluie visible sans être trop sombre
  }

  // Orage (11d/11n)
  if (iconCode.startsWith('11')) {
    return [const Color(0xFF37474F), const Color(0xFF102027)]; // Gris très sombre avec touche bleue → éclair ⚡ pop
  }

  // Neige (13d/13n)
  if (iconCode.startsWith('13')) {
    return [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)]; // Bleu très clair → flocons ❄️ bien visibles
  }

  // Brume/brouillard (50d/50n)
  if (iconCode.startsWith('50')) {
    return [const Color(0xFFCFD8DC), const Color(0xFF90A4AE)]; // Gris clair brumeux
  }

  // Par défaut (ex: autres codes rares)
  return isNight
      ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
      : [const Color(0xFF87CEEB), const Color(0xFF00BFFF)];
}

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
    final current = widget.weatherData['current'];
    final forecast = widget.weatherData['forecast'] as List<dynamic>;
    final alerts = widget.weatherData['alerts'] as List<dynamic>;
    final location = widget.weatherData['location'];
    final iconCode = current['icon'];
    final gradientColors = getWeatherGradient(iconCode);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.more_vert, color: Colors.white),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Fond animé
          AnimatedWeatherBackground(
            controller: _controller,
            iconCode: iconCode,
            gradientColors: gradientColors,
          ),

          // Contenu principal
          FadeTransition(
            opacity: _fadeController,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // En-tête avec localisation et température
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_on, color: Colors.white, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                location['name'],
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${current['temperature']}°",
                            style: const TextStyle(
                              fontSize: 96,
                              fontWeight: FontWeight.w200,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Grand emoji pour le temps actuel
                          Text(
                            getWeatherEmoji(current['icon']),
                            style: const TextStyle(fontSize: 80),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            current['description'],
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Max ${current['temp_max']}° • Min ${current['temp_min']}°",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Prévisions sur 5 jours
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.schedule, color: Colors.white.withOpacity(0.8), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                "PRÉVISIONS SUR 5 JOURS",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...forecast.map((day) => _buildForecastRow(day)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Détails météo
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildDetailTile("Ressenti", "${current['feels_like']}°", Icons.thermostat)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildDetailTile("Humidité", "${current['humidity']}%", Icons.water_drop)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildDetailTile("Vent", "${current['wind_speed']} km/h", Icons.air)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildDetailTile("Pression", "${current['pressure']} hPa", Icons.speed)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildDetailTile("Visibilité", "${current['visibility']} km", Icons.visibility)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildDetailTile("UV Index", "3", Icons.wb_sunny_outlined)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Lever/Coucher du soleil
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Icon(Icons.wb_twilight, color: Colors.white, size: 32),
                              const SizedBox(height: 8),
                              Text(
                                "Lever",
                                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                current['sunrise'],
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Container(height: 60, width: 1, color: Colors.white.withOpacity(0.3)),
                          Column(
                            children: [
                              const Icon(Icons.nights_stay, color: Colors.white, size: 32),
                              const SizedBox(height: 8),
                              Text(
                                "Coucher",
                                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                current['sunset'],
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Alertes agricoles
                    if (alerts.isNotEmpty) ...[
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Alertes agricoles",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            ...alerts.map((alert) => _buildAlertCard(alert)),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white, size: 28),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Aucune alerte - Conditions favorables",
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastRow(Map<String, dynamic> day) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              day['day_name'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            getWeatherEmoji(day['icon']),
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 40,
            child: Text(
              "${day['rain_probability']}%",
              style: TextStyle(
                color: Colors.cyan[200],
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
          Text(
            "${day['temp_min'].toInt()}°",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 17,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 60,
            height: 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: LinearGradient(
                colors: [Colors.cyan[400]!, Colors.orange[400]!],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "${day['temp_max'].toInt()}°",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.7), size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
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
              Expanded(
                child: Text(
                  alert['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(alert['message'], style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          ...alert['recommendations'].map<Widget>((rec) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(rec, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// Widget d'arrière-plan animé
class AnimatedWeatherBackground extends StatelessWidget {
  final AnimationController controller;
  final String? iconCode;
  final List<Color> gradientColors;

  const AnimatedWeatherBackground({
    super.key,
    required this.controller,
    required this.iconCode,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
      ),
      child: Stack(
        children: [
          // Particules animées
          ...List.generate(20, (index) {
            return AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                final offset = (controller.value + index * 0.05) % 1.0;
                return Positioned(
                  left: (index * 47) % MediaQuery.of(context).size.width,
                  top: offset * MediaQuery.of(context).size.height,
                  child: Opacity(
                    opacity: 0.3,
                    child: _getWeatherParticle(iconCode),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _getWeatherParticle(String? iconCode) {
    if (iconCode == null) return const SizedBox();

    if (iconCode.startsWith('01')) {
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
        ),
      );
    } else if (iconCode.startsWith('09') || iconCode.startsWith('10')) {
      return Container(
        width: 3,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      );
    } else if (iconCode.startsWith('13')) {
      return const Icon(Icons.ac_unit, color: Colors.white, size: 20);
    } else {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.15),
        ),
      );
    }
  }
}