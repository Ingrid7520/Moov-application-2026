// lib/screens/auth/auth_screens.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/user_service.dart';
import '../../main.dart';
import '../terms/terms_screen.dart';

// ============================================================================
// CONFIGURATION API
// ============================================================================
const String baseUrl = 'http://192.168.1.161:8001/api';  // ✅ Changez selon votre IP

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
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // ✅ FORMATER LE NUMÉRO CORRECTEMENT
  String _formatPhoneNumber(String input) {
    // Retirer tous les caractères non-numériques
    String digitsOnly = input.replaceAll(RegExp(r'\D'), '');

    // Si commence déjà par 225, garder tel quel
    if (digitsOnly.startsWith('225')) {
      return '+$digitsOnly';
    }

    // Si commence par 0, ajouter 225 AVANT le 0
    if (digitsOnly.startsWith('0')) {
      return '+225$digitsOnly';  // ✅ +2250172957171
    }

    // Sinon, ajouter 2250 devant
    return '+2250$digitsOnly';
  }

  Future<void> _sendLoginCode() async {
    final rawPhone = _phoneController.text.trim();

    if (rawPhone.isEmpty || rawPhone.length < 8) {
      _showError("Veuillez entrer un numéro valide");
      return;
    }

    // ✅ Formater le numéro
    final phone = _formatPhoneNumber(rawPhone);

    setState(() => _isLoading = true);

    try {
      print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      print("ENVOI CODE DE CONNEXION");
      print("URL: $baseUrl/auth/login");
      print("Phone brut: $rawPhone");
      print("Phone formaté: $phone");
      print("Longueur: ${phone.length} caractères");
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
        if (data.containsKey('test_otp')) {
          print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
          print("🔐 CODE OTP (DEV): ${data['test_otp']}");
          print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Code envoyé avec succès !'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

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
        String errorMessage = 'Erreur lors de l\'envoi du code';

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
      _showError("Erreur de connexion au serveur");
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

                  // ✅ Champ Numéro avec +225 en préfixe
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        // Préfixe +225
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Row(
                            children: [
                              Icon(Icons.phone_android, color: Colors.green[700]),
                              const SizedBox(width: 8),
                              const Text(
                                '+225',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                height: 24,
                                width: 1,
                                color: Colors.grey[300],
                              ),
                            ],
                          ),
                        ),
                        // Champ de saisie
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10), // Max 10 chiffres
                            ],
                            decoration: InputDecoration(
                              hintText: "0172957171",
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
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
                  SafeArea(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                        left: 16,
                        right: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Flexible(
                            child: Text(
                              "Pas encore de compte ?",
                              style: TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
// ÉCRAN DE VÉRIFICATION OTP - AVEC AUTO-REMPLISSAGE
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
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isAutoFilling = false;
  Timer? _autoFillTimer;

  @override
  void initState() {
    super.initState();
    // ✅ DÉMARRER AUTO-REMPLISSAGE APRÈS 2 SECONDES
    _autoFillTimer = Timer(const Duration(seconds: 2), _autoFillOTP);
  }

  @override
  void dispose() {
    _autoFillTimer?.cancel();
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

  // ============================================================================
  // 🆕 AUTO-REMPLISSAGE OTP DEPUIS MONGODB
  // ============================================================================
  Future<void> _autoFillOTP() async {
    if (!mounted) return;

    setState(() => _isAutoFilling = true);

    try {
      print('🔍 Récupération OTP automatique...');
      print('📞 Phone: ${widget.phoneNumber}');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/get-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phone_number': widget.phoneNumber}),
      );

      print('📥 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String code = data['code'];

        print('✅ Code OTP récupéré: $code');

        if (mounted && code.length == 6) {
          // Remplir les champs un par un avec animation
          for (int i = 0; i < 6; i++) {
            await Future.delayed(const Duration(milliseconds: 150));
            if (mounted) {
              _controllers[i].text = code[i];
            }
          }

          // Vérifier automatiquement après 500ms
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            _verifyOtp();
          }
        }
      } else {
        print('⚠️ Code OTP non trouvé - L\'utilisateur devra le saisir');
      }
    } catch (e) {
      print('❌ Erreur auto-remplissage: $e');
    } finally {
      if (mounted) {
        setState(() => _isAutoFilling = false);
      }
    }
  }

  // Vérifier automatiquement quand les 6 chiffres sont entrés manuellement
  void _checkAutoVerify() {
    if (_otpCode.length == 6 && !_isLoading && !_isAutoFilling) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_otpCode.length == 6 && !_isLoading) {
          _verifyOtp();
        }
      });
    }
  }

  // ============================================================================
  // VÉRIFICATION OTP
  // ============================================================================
  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) {
      _showError("Veuillez entrer les 6 chiffres");
      return;
    }

    setState(() => _isLoading = true);

    try {
      print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      print("VÉRIFICATION OTP");
      print("Phone: ${widget.phoneNumber}");
      print("Code: $_otpCode");
      print("Type: ${widget.isRegistration ? 'Inscription' : 'Connexion'}");
      print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone_number": widget.phoneNumber,
          "code": _otpCode,
        }),
      );

      print("Status Code: ${response.statusCode}");

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        final token = data['access_token'] ?? data['token'];

        if (token != null) {
          // Sauvegarder token + données utilisateur
          await UserService.saveToken(token);

          if (data['user'] != null) {
            await UserService.saveUserData(data['user']);

            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            print("✅ DONNÉES UTILISATEUR SAUVEGARDÉES");
            print("Token: ${token.substring(0, 20)}...");
            print("User Type: ${data['user']['user_type']}");
            print("Name: ${data['user']['name']}");
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Connexion réussie !'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainScaffold()),
                  (route) => false,
            );
          }
        } else {
          print("❌ Aucun token trouvé");
          _showError("Erreur: Token manquant");
        }
      } else {
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
      _showError("Erreur de connexion");
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Code renvoyé !'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Relancer l'auto-remplissage
          _autoFillTimer?.cancel();
          _autoFillTimer = Timer(const Duration(seconds: 2), _autoFillOTP);
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

            // ✅ CHAMPS OTP AVEC ANIMATION AUTO-REMPLISSAGE
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
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      counterText: "",
                      filled: true,
                      fillColor: _isAutoFilling ? Colors.green[50] : Colors.grey[100],
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
                        if (index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else {
                          _focusNodes[index].unfocus();
                          _checkAutoVerify();
                        }
                      } else {
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

            // ✅ INDICATEUR AUTO-REMPLISSAGE
            if (_isAutoFilling)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Récupération automatique...',
                    style: TextStyle(color: Colors.green[700], fontSize: 13),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Bouton Vérifier
            ElevatedButton(
              onPressed: (_isLoading || _isAutoFilling) ? null : _verifyOtp,
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
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                const Text("Vous n'avez pas reçu le code ?"),
                TextButton(
                  onPressed: _resendCode,
                  child: Text(
                    "Renvoyer",
                    style: TextStyle(
                      fontSize: 14,
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
  final _phoneController = TextEditingController();
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

  // ✅ FORMATER LE NUMÉRO CORRECTEMENT
  String _formatPhoneNumber(String input) {
    String digitsOnly = input.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.startsWith('225')) {
      return '+$digitsOnly';
    }

    if (digitsOnly.startsWith('0')) {
      return '+225$digitsOnly';  // ✅ +2250172957171
    }

    return '+2250$digitsOnly';
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final rawPhone = _phoneController.text.trim();
    final location = _locationController.text.trim();

    if (name.isEmpty || rawPhone.isEmpty || rawPhone.length < 8) {
      _showError("Veuillez remplir tous les champs");
      return;
    }

    // ✅ Formater le numéro
    final phone = _formatPhoneNumber(rawPhone);

    setState(() => _isLoading = true);

    try {
      print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      print("INSCRIPTION");
      print("Name: $name");
      print("Phone brut: $rawPhone");
      print("Phone formaté: $phone");
      print("Longueur: ${phone.length} caractères");
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
          print("🔐 CODE OTP (DEV): ${data['test_otp']}");
          print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Inscription réussie !'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

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
        String errorMessage = 'Erreur lors de l\'inscription';

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
      _showError("Erreur de connexion");
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

            // ✅ Champ Téléphone avec +225
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Row(
                      children: [
                        Icon(Icons.phone_android, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        const Text(
                          '+225',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          height: 24,
                          width: 1,
                          color: Colors.grey[300],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: InputDecoration(
                        hintText: "0172957171",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ],
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

            // Conditions d'utilisation
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  Text(
                    'En vous inscrivant, vous acceptez nos ',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TermsScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Conditions d\'utilisation',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),

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