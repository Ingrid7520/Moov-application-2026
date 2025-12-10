import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';
import '../widgets/quick_action_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            // --- En-tête avec dégradé ---
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

                  // Widget Météo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.cloud, color: Colors.white, size: 40),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("28°C",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold)),
                                Text("Abidjan, Nuageux",
                                    style: TextStyle(color: Colors.green[100])),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("Humidité", style: TextStyle(color: Colors.white)),
                            Text("75%",
                                style: TextStyle(
                                    color: Colors.green[100],
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- Actions Rapides ---
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
                    // CORRECTION : 0.95 augmente légèrement la hauteur par rapport à 1.0
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

            // --- Statistiques ---
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