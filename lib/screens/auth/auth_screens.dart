// lib/screens/auth/auth_screens.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/user_service.dart'; // ← AJOUT IMPORTANT
import '../../main.dart'; // ← Pour MainScaffold
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

  // ============================================================================
  // 🔥 MODIFIÉ : Sauvegarde des données utilisateur avec UserService
  // ============================================================================
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
          "code": _otpCode,
        }),
      );

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        // Vérifier si le token existe
        final token = data['access_token'] ?? data['token'];

        if (token != null) {
          // ===== MODIFICATION IMPORTANTE : Utiliser UserService =====
          // 1. Sauvegarder le token JWT
          await UserService.saveToken(token);

          // 2. Sauvegarder les données utilisateur (CRITIQUE pour la navigation conditionnelle)
          if (data['user'] != null) {
            await UserService.saveUserData(data['user']);

            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            print("✅ DONNÉES UTILISATEUR SAUVEGARDÉES");
            print("Token: ${token.substring(0, 20)}...");
            print("User Type: ${data['user']['user_type']}");
            print("Name: ${data['user']['name']}");
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
          } else {
            print("⚠️ ATTENTION : 'user' absent dans la réponse API");
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Connexion réussie !'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );

            // Redirection vers l'écran principal (navigation conditionnelle gérée dans MainScaffold)
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
              content: Text('Code renvoyé !'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print("❌ Erreur renvoie code: $e");
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
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[400]!, Colors.green[700]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline, color: Colors.white, size: 50),
            ),

            const SizedBox(height: 32),

            const Text(
              "Vérification",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              "Code envoyé au ${widget.phoneNumber}",
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            // Champs OTP (6 digits)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 45,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      counterText: "",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.green[700]!, width: 2),
                      ),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        // Passer au champ suivant
                        if (index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else {
                          // Dernier champ, lancer la vérification auto
                          _focusNodes[index].unfocus();
                          _checkAutoVerify();
                        }
                      } else {
                        // Revenir au champ précédent si suppression
                        if (index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      }
                    },
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            // Bouton Vérifier
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyOtp,
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
                "Vérifier",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Lien Renvoyer le code
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Vous n'avez pas reçu le code ?"),
                TextButton(
                  onPressed: _resendCode,
                  child: Text(
                    "Renvoyer",
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

    if (name.isEmpty || phone.length < 8) {
      _showError("Veuillez remplir tous les champs");
      return;
    }

    setState(() => _isLoading = true);

    try {
      print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      print("INSCRIPTION");
      print("Name: $name");
      print("Phone: $phone");
      print("Location: $location");
      print("User Type: $_userType");
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

      if (response.statusCode == 201 || response.statusCode == 200) {
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
          Navigator.push(
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
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[400]!, Colors.green[700]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.spa, color: Colors.white, size: 40),
            ),

            const SizedBox(height: 24),

            const Text(
              "Inscription",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Créez votre compte AgriSmart CI",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),

            const SizedBox(height: 32),

            // Champ Nom
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.person, color: Colors.green[700]),
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

            // Champ Téléphone
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