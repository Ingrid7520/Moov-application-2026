import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../widgets/common_widgets.dart';

// --- Écran de Connexion (Login) ---
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // En-tête décoratif
            Container(
              height: 300,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[600]!, Colors.green[800]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(60)),
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

            // Formulaire
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Connexion",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Entrez vos informations pour recevoir votre code",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 32),

                  // Champ Nom d'utilisateur (Modifié)
                  const CustomTextField(
                    label: "Nom d'utilisateur",
                    icon: Icons.person,
                  ),

                  // Champ Numéro de téléphone
                  const CustomTextField(
                    label: "Numéro de téléphone",
                    icon: Icons.phone_android,
                    keyboardType: TextInputType.phone,
                    prefixText: "+225 ",
                  ),

                  const SizedBox(height: 24),

                  // Bouton Recevoir Code (Modifié)
                  ElevatedButton(
                    onPressed: () {
                      // Redirection vers l'écran de vérification OTP
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OtpVerificationScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                    child: const Text(
                      "Recevoir code",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Pas encore de compte ?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: Text(
                          "S'inscrire",
                          style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
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

// --- Écran de Vérification OTP (Nouveau) ---
class OtpVerificationScreen extends StatelessWidget {
  const OtpVerificationScreen({super.key});

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
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              "Entrez le code à 6 chiffres envoyé",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 40),

            // Champs pour les 6 chiffres (Row avec 6 TextFields)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 45,
                  height: 55,
                  child: TextField(
                    onChanged: (value) {
                      // Passer automatiquement au champ suivant si un chiffre est entré
                      if (value.length == 1 && index < 5) {
                        FocusScope.of(context).nextFocus();
                      }
                      // Revenir au champ précédent si on efface (optionnel, simple ici)
                      if (value.isEmpty && index > 0) {
                        FocusScope.of(context).previousFocus();
                      }
                    },
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                        borderSide: BorderSide(color: Colors.green.shade700, width: 2),
                      ),
                      fillColor: Colors.grey[100],
                      filled: true,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                // Validation du code et connexion finale
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MainScaffold()),
                      (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
              child: const Text(
                "Vérifier et se connecter",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () {
                  // Logique pour renvoyer le code
                },
                child: Text(
                  "Renvoyer le code",
                  style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Écran d'Inscription (Register) ---
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

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
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              "Rejoignez la communauté AgriSmart",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),

            // Nom complet
            const CustomTextField(
              label: "Nom complet",
              icon: Icons.person_outline,
            ),

            // Numéro de téléphone
            const CustomTextField(
              label: "Numéro de téléphone",
              icon: Icons.phone_android,
              keyboardType: TextInputType.phone,
              prefixText: "+225 ",
            ),

            // Note : Email et Mots de passe supprimés selon la demande

            const SizedBox(height: 16),

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
                          style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () {
                // Inscription réussie -> Accès direct à l'accueil
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MainScaffold()),
                      (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
              child: const Text(
                "S'inscrire",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Déjà un compte ?"),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Se connecter",
                    style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
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