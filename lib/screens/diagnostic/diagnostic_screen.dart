import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  bool showResult = false;
  bool isLoading = false;
  File? selectedImage;

  // Résultats du diagnostic
  String? diseaseName;
  String? plantName;
  String? severity;
  String? description;
  List<String> treatments = [];
  String? errorMessage;

  final ImagePicker _picker = ImagePicker();
  final String apiUrl = 'http://192.168.1.161:8000/api/chat/';

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
              child: isLoading
                  ? _buildLoadingView()
                  : showResult
                  ? _buildResultView()
                  : _buildCaptureView(),
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
        // Zone de capture
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.blue.shade300, width: 2),
          ),
          child: Column(
            children: [
              if (selectedImage != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    selectedImage!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _analyzeImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text("Analyser cette image"),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() => selectedImage = null),
                  child: const Text("Choisir une autre photo"),
                ),
              ] else ...[
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child : ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Caméra",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child :ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text("Galerie"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          const Text(
            "Analyse en cours...",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "L'IA analyse votre image",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    final bool hasDisease = diseaseName != null && diseaseName!.toLowerCase() != "aucune maladie détectée";

    // Définir les couleurs selon la sévérité
    List<Color> gradientColors;
    Color chipColor;
    Color chipBgColor;

    if (hasDisease) {
      if (severity == "Sévère") {
        gradientColors = [Colors.red[400]!, Colors.red[600]!];
        chipColor = Colors.red[700]!;
        chipBgColor = Colors.red[50]!;
      } else if (severity == "Modéré") {
        gradientColors = [Colors.orange[400]!, Colors.orange[600]!];
        chipColor = Colors.orange[700]!;
        chipBgColor = Colors.orange[50]!;
      } else {
        gradientColors = [Colors.yellow[400]!, Colors.yellow[700]!];
        chipColor = Colors.yellow[800]!;
        chipBgColor = Colors.yellow[50]!;
      }
    } else {
      gradientColors = [Colors.green[400]!, Colors.green[600]!];
      chipColor = Colors.green[700]!;
      chipBgColor = Colors.green[50]!;
    }

    if (errorMessage != null) {
      return _buildErrorView();
    }

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Column(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        hasDisease ? Icons.warning : Icons.check_circle,
                        color: Colors.white,
                        size: 50
                    ),
                    const SizedBox(height: 8),
                    Text(
                        hasDisease ? "Maladie détectée" : "Plant sain",
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                    if (plantName != null)
                      Text(
                          plantName!,
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)
                      ),
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
                        Expanded(
                          child: Text(
                              diseaseName ?? "Résultat",
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                          ),
                        ),
                        if (severity != null)
                          Chip(
                            label: Text(
                                severity!,
                                style: TextStyle(color: chipColor)
                            ),
                            backgroundColor: chipBgColor,
                          )
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                        description ?? "Aucune description disponible",
                        style: const TextStyle(color: Colors.grey)
                    ),
                    if (treatments.isNotEmpty) ...[
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
                            const Text(
                                "Traitement recommandé",
                                style: TextStyle(fontWeight: FontWeight.bold)
                            ),
                            const SizedBox(height: 8),
                            ...treatments.map((treatment) => _buildTreatmentStep(treatment)),
                          ],
                        ),
                      ),
                    ],
                    if (hasDisease) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.white),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Cette fonctionnalité sera disponible prochainement. '
                                            'Un expert agricole vous contactera.',
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.green[700],
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 4),
                              ),
                            );
                          },
                          icon: Icon(Icons.support_agent),
                          label: Text("Contacter Expert"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _resetDiagnostic,
          child: const Text("Nouveau diagnostic"),
        )
      ],
    );
  }

  Widget _buildErrorView() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          const Text(
            "Erreur d'analyse",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _resetDiagnostic,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text("Réessayer"),
          ),
        ],
      ),
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
          CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: const Icon(Icons.camera_alt, color: Colors.blue, size: 20)
          ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: CircleAvatar(radius: 3, backgroundColor: Colors.blue),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la sélection: $e"))
      );
    }
  }

  Future<void> _analyzeImage() async {
    if (selectedImage == null) return;

    setState(() {
      isLoading = true;
      showResult = false;
      errorMessage = null;
    });

    try {
      // Convertir l'image en base64
      final bytes = await selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Préparer le prompt optimisé
      const String prompt = """Analyse cette image de plante et réponds UNIQUEMENT au format JSON suivant (sans aucun texte avant ou après) :

{
  "plant_name": "Nom de la plante en français",
  "disease_name": "Nom de la maladie OU 'Aucune maladie détectée'",
  "severity": "Sévère" OU "Modéré" OU "Léger" OU null,
  "description": "Description courte de la maladie (max 2 phrases)",
  "treatments": ["Traitement 1", "Traitement 2", "Traitement 3"]
}

Si aucune maladie n'est détectée, mets disease_name à "Aucune maladie détectée", severity à null, description à "La plante semble en bonne santé" et treatments à [].""";

      // Envoyer la requête à l'API
      final request = http.Request(
        'POST',
        Uri.parse(apiUrl),
      );

      request.headers['Content-Type'] = 'application/json';
      request.body = json.encode({
        'message': prompt,
        'image_base64': 'data:image/jpeg;base64,$base64Image',
        'session_id': 'diagnostic_${DateTime.now().millisecondsSinceEpoch}'
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String responseText = data['response'];

        // Parser la réponse JSON de Gemini
        _parseGeminiResponse(responseText);

        setState(() {
          showResult = true;
        });
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = "Impossible d'analyser l'image. Vérifiez votre connexion.\n\nDétails: $e";
        showResult = true;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _parseGeminiResponse(String response) {
    try {
      // Nettoyer la réponse (enlever les ```json ou ``` si présents)
      String cleanedResponse = response.trim();
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      }
      if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
      }
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
      }
      cleanedResponse = cleanedResponse.trim();

      final data = json.decode(cleanedResponse);

      setState(() {
        plantName = data['plant_name'];
        diseaseName = data['disease_name'];
        severity = data['severity'];
        description = data['description'];
        treatments = List<String>.from(data['treatments'] ?? []);
      });
    } catch (e) {
      // Si le parsing JSON échoue, essayer d'extraire les infos du texte
      setState(() {
        diseaseName = "Analyse réussie";
        description = response.length > 200 ? response.substring(0, 200) + "..." : response;
        treatments = [];
      });
    }
  }

  void _resetDiagnostic() {
    setState(() {
      showResult = false;
      selectedImage = null;
      diseaseName = null;
      plantName = null;
      severity = null;
      description = null;
      treatments = [];
      errorMessage = null;
    });
  }
}