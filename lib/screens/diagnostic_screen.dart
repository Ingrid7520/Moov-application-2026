import 'package:flutter/material.dart';

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  bool showResult = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // En-tête
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.blue[700]!],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Diagnostic IA",
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Identifiez les maladies de vos cultures",
                    style: TextStyle(color: Colors.blue[100])),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: showResult ? _buildResultView() : _buildCaptureView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Zone de capture factice
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.blue.shade300, style: BorderStyle.solid), // Pointillés difficiles sans package externe
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              const Text("Prenez une photo",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Photographiez la partie malade",
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => setState(() => showResult = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: const StadiumBorder(),
                ),
                child: const Text("Ouvrir la caméra"),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text("Diagnostics récents",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildHistoryItem("Cacaoyer", "Pourriture brune", "Il y a 2 jours"),
        const SizedBox(height: 12),
        _buildHistoryItem("Anacardier", "Anthracnose", "Il y a 5 jours"),
      ],
    );
  }

  Widget _buildResultView() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Column(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.green[400]!, Colors.green[600]!]),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 50),
                    SizedBox(height: 8),
                    Text("Analyse terminée", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Pourriture noire",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Chip(
                          label: const Text("Sévère", style: TextStyle(color: Colors.red)),
                          backgroundColor: Colors.red[50],
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text("Maladie fongique affectant principalement les cacaoyers...",
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Traitement recommandé",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          _buildTreatmentStep("Appliquer fongicide base cuivre"),
                          _buildTreatmentStep("Éliminer cabosses infectées"),
                          _buildTreatmentStep("Améliorer drainage sol"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text("Commander intrants"),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => setState(() => showResult = false),
          child: const Text("Nouveau diagnostic"),
        )
      ],
    );
  }

  Widget _buildHistoryItem(String title, String subtitle, String date) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.blue[100], child: const Icon(Icons.camera_alt, color: Colors.blue, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTreatmentStep(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const CircleAvatar(radius: 3, backgroundColor: Colors.blue),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}