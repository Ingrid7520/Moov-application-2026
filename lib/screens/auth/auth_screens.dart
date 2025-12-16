// lib/screens/auth/auth_screens.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../home/home_screen.dart';
import '../diagnostic/diagnostic_screen.dart';
import '../market/market_screen.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';

// Configuration API - MODIFIER CETTE URL SELON VOTRE CONFIGURATION
// Pour émulateur Android: 10.0.2.2
// Pour téléphone physique: votre IP locale (ex: 192.168.1.16)
const String baseUrl = 'http://10.0.2.2:8001/api';

// =============================================================================
// ÉCRAN DE CONNEXION (LOGIN)
// =============================================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _storage = const FlutterSecureStorage();
  final _phoneController = TextEditingController(text: "+225");
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendLoginCode() async {
    final phone = _phoneController.text.trim();

    if (phone.length < 8) {
      _showError("Veuillez entrer un numéro valide");
      return;
    }

    setState(() => _isLoading = true);

    try {
      print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      print("ENVOI CODE DE CONNEXION");
      print("URL: $baseUrl/auth/login");
      print("Phone: $phone");
      print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone_number": phone}),
      );

      print("Status Code: ${response.statusCode}");
      print("Response: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Code envoyé avec succès
        if (data.containsKey('test_otp')) {
          print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
          print("CODE OTP (DEV): ${data['test_otp']}");
          print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Code envoyé avec succès !'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                phoneNumber: phone,
                isRegistration: false,
              ),
            ),
          );
        }
      } else {
        final errorMessage = data['detail'] ?? data['message'] ?? 'Erreur lors de l\'envoi du code';
        print("❌ Erreur: $errorMessage");
        _showError(errorMessage);
      }
    } catch (e) {
      print("❌ Exception: $e");
      _showError("Erreur de connexion au serveur: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // En-tête décoratif avec gradient
            Container(
              height: 300,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[600]!, Colors.green[800]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(60),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.spa, color: Colors.white, size: 50),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "AgriSmart CI",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Votre compagnon agricole",
                      style: TextStyle(color: Colors.green[100], fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            // Formulaire de connexion
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Connexion",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Entrez votre numéro pour recevoir un code",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 32),

                  // Champ Numéro de téléphone
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.phone_android, color: Colors.green[700]),
                        hintText: "Numéro de téléphone",
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bouton Recevoir Code
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendLoginCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      "Recevoir le code",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Lien vers l'inscription
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Pas encore de compte ?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "S'inscrire",
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// ÉCRAN DE VÉRIFICATION OTP
// =============================================================================
class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final bool isRegistration;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.isRegistration,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _storage = const FlutterSecureStorage();
  final List<TextEditingController> _controllers = List.generate(
    6,
        (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otpCode {
    return _controllers.map((c) => c.text).join();
  }

  // Vérifier automatiquement quand les 6 chiffres sont entrés
  void _checkAutoVerify() {
    if (_otpCode.length == 6 && !_isLoading) {
      // Petit délai pour une meilleure UX
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_otpCode.length == 6 && !_isLoading) {
          _verifyOtp();
        }
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) {
      _showError("Veuillez entrer les 6 chiffres");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Utiliser le même endpoint pour connexion et inscription
      const endpoint = '/auth/verify-otp';

      print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      print("VÉRIFICATION OTP");
      print("Endpoint: $baseUrl$endpoint");
      print("Phone: ${widget.phoneNumber}");
      print("Code: $_otpCode");
      print("Type: ${widget.isRegistration ? 'Inscription' : 'Connexion'}");
      print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone_number": widget.phoneNumber,
          "code": _otpCode,  // ✅ Utiliser "code" au lieu de "otp"
        }),
      );

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Vérifier si le token existe (peut être 'access_token' ou 'token')
        final token = data['access_token'] ?? data['token'];

        if (token != null) {
          // Sauvegarde du token JWT
          await _storage.write(key: 'jwt_token', value: token);

          print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
          print("✅ TOKEN SAUVEGARDÉ AVEC SUCCÈS");
          print("Token: ${token.substring(0, 20)}...");
          print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Connexion réussie !'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );

            // Redirection vers l'écran principal
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainScaffold()),
                  (route) => false,
            );
          }
        } else {
          print("❌ Aucun token trouvé dans la réponse");
          _showError("Erreur: Token manquant dans la réponse");
        }
      } else {
        // Meilleure gestion des erreurs
        String errorMessage = 'Code incorrect';

        if (data is Map) {
          if (data.containsKey('detail')) {
            final detail = data['detail'];
            if (detail is String) {
              errorMessage = detail;
            } else if (detail is List && detail.isNotEmpty) {
              errorMessage = detail[0]['msg'] ?? 'Erreur de validation';
            }
          } else if (data.containsKey('message')) {
            errorMessage = data['message'];
          }
        }

        print("❌ Erreur: $errorMessage");
        _showError(errorMessage);
      }
    } catch (e) {
      print("❌ Exception: $e");
      _showError("Erreur de connexion: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendCode() async {
    try {
      final endpoint = widget.isRegistration ? '/auth/register' : '/auth/login';

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone_number": widget.phoneNumber}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('test_otp')) {
          print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
          print("NOUVEAU CODE OTP: ${data['test_otp']}");
          print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nouveau code envoyé !'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      _showError("Erreur lors du renvoi: $e");
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Vérification",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Code envoyé au ${widget.phoneNumber}",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 40),

            // Champs OTP
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 45,
                  height: 55,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    onChanged: (value) {
                      if (value.length == 1 && index < 5) {
                        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                      }
                      if (value.isEmpty && index > 0) {
                        FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
                      }

                      // ✅ Vérification automatique quand les 6 chiffres sont entrés
                      _checkAutoVerify();
                    },
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(1),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.green.shade700,
                          width: 2,
                        ),
                      ),
                      fillColor: Colors.grey[100],
                      filled: true,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 40),

            // Indicateur de vérification automatique
            if (_isLoading)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.green,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Vérification en cours...",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
            // Bouton Vérifier (manuel si besoin)
              ElevatedButton(
                onPressed: _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  "Vérifier manuellement",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Bouton Renvoyer le code
            Center(
              child: TextButton(
                onPressed: _resendCode,
                child: Text(
                  "Renvoyer le code",
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// ÉCRAN D'INSCRIPTION (REGISTER)
// =============================================================================
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(text: "+225");
  final _locationController = TextEditingController();
  String _userType = 'producer';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final location = _locationController.text.trim();

    if (name.isEmpty || phone.length < 8 || location.isEmpty) {
      _showError("Veuillez remplir tous les champs");
      return;
    }

    setState(() => _isLoading = true);

    try {
      print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      print("INSCRIPTION NOUVEAU COMPTE");
      print("URL: $baseUrl/auth/register");
      print("Name: $name");
      print("Phone: $phone");
      print("Location: $location");
      print("Type: $_userType");
      print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "phone_number": phone,
          "location": location,
          "user_type": _userType,
        }),
      );

      print("Status Code: ${response.statusCode}");
      print("Response: ${response.body}");

      final data = jsonDecode(response.body);

      // ✅ Accepter 200 ET 201 (Created)
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data.containsKey('test_otp')) {
          print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
          print("CODE OTP (DEV): ${data['test_otp']}");
          print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Inscription réussie !'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                phoneNumber: phone,
                isRegistration: true,
              ),
            ),
          );
        }
      } else {
        final errorMessage = data['detail'] ?? data['message'] ?? 'Erreur lors de l\'inscription';
        print("❌ Erreur: $errorMessage");
        _showError(errorMessage);
      }
    } catch (e) {
      print("❌ Exception: $e");
      _showError("Erreur de connexion: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Créer un compte",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Rejoignez la communauté AgriSmart",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),

            // Champ Nom complet
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.person_outline, color: Colors.green[700]),
                  hintText: "Nom complet",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Champ Numéro de téléphone
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.phone_android, color: Colors.green[700]),
                  hintText: "Numéro de téléphone",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Champ Localité
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.location_on, color: Colors.green[700]),
                  hintText: "Ville / Localité",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Dropdown Type d'utilisateur
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButtonFormField<String>(
                value: _userType,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.category, color: Colors.green[700]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                dropdownColor: Colors.white,
                items: const [
                  DropdownMenuItem(
                    value: 'producer',
                    child: Text("Producteur"),
                  ),
                  DropdownMenuItem(
                    value: 'buyer',
                    child: Text("Acheteur"),
                  ),
                  DropdownMenuItem(
                    value: 'both',
                    child: Text("Les deux"),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _userType = val);
                  }
                },
              ),
            ),

            const SizedBox(height: 24),

            // Acceptation des conditions
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: "J'accepte les ",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      children: [
                        TextSpan(
                          text: "Conditions d'utilisation",
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Bouton S'inscrire
            ElevatedButton(
              onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                "S'inscrire",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Lien vers la connexion
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Déjà un compte ?"),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Se connecter",
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// STRUCTURE PRINCIPALE DE L'APPLICATION (MainScaffold)
// =============================================================================
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  // Liste des écrans principaux
  final List<Widget> _screens = const [
    HomeScreen(),
    DiagnosticScreen(),
    MarketScreen(),
    ChatScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.green[700],
          unselectedItemColor: Colors.grey[400],
          showUnselectedLabels: true,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt),
              label: 'Diagnostic',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up),
              label: 'Marchés',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}