import 'package:flutter/material.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.green[600]!, Colors.green[700]!]),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Prix du marché",
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        Text("En temps réel", style: TextStyle(color: Colors.green[100])),
                      ],
                    ),
                    Chip(
                      avatar: const Icon(Icons.location_on, size: 16, color: Colors.red),
                      label: const Text("Abidjan", style: TextStyle(color: Colors.red)),
                      backgroundColor: Colors.white.withOpacity(0.2),
                      side: BorderSide.none,
                    )
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  decoration: InputDecoration(
                    hintText: "Rechercher un produit...",
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text("Produits populaires",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildPriceCard("Cacao", "1,850 FCFA/kg", "+5.2%", true),
                _buildPriceCard("Anacarde", "1,200 FCFA/kg", "+2.1%", true),
                _buildPriceCard("Manioc", "350 FCFA/kg", "-1.5%", false),
                _buildPriceCard("Café", "2,100 FCFA/kg", "+3.8%", true),

                const SizedBox(height: 24),
                const Text("Marchés actifs",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildMarketCard("Marché d'Adjamé", "2.3 km", "145 vendeurs"),
                _buildMarketCard("Marché de Bouaké", "15 km", "89 vendeurs"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(String name, String price, String percent, bool isUp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.inventory_2, color: Colors.green[700]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(price, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Text(percent, style: TextStyle(
              color: isUp ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold
          )),
        ],
      ),
    );
  }

  Widget _buildMarketCard(String name, String dist, String active) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(dist, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Text(active, style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}