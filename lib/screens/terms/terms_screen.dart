// lib/screens/terms/terms_screen.dart
/// 📄 Conditions d'Utilisation
/// Accessible depuis RegisterScreen

import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Conditions d\'Utilisation'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.description,
                    size: 64,
                    color: Colors.green[700],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Conditions d\'Utilisation',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dernière mise à jour : 18 Décembre 2025',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Introduction
            _buildSection(
              '1. Acceptation des Conditions',
              'En utilisant l\'application AgriSmart CI, vous acceptez d\'être lié par '
                  'les présentes conditions d\'utilisation. Si vous n\'acceptez pas ces '
                  'conditions, veuillez ne pas utiliser l\'application.\n\n'
                  'Ces conditions s\'appliquent à tous les utilisateurs de l\'application, '
                  'y compris les producteurs agricoles, les acheteurs, et les autres '
                  'utilisateurs du service.',
            ),

            _buildSection(
              '2. Description du Service',
              'AgriSmart CI est une plateforme mobile dédiée à l\'agriculture en Côte d\'Ivoire '
                  'qui offre les services suivants :\n\n'
                  '• Diagnostic de maladies des cultures par intelligence artificielle\n'
                  '• Consultation météorologique adaptée à l\'agriculture\n'
                  '• Marketplace pour l\'achat et la vente de produits agricoles\n'
                  '• Assistance agricole par chatbot IA (AgriBot)\n'
                  '• Suivi de prix des marchés agricoles\n'
                  '• Conseils agricoles personnalisés',
            ),

            _buildSection(
              '3. Inscription et Compte Utilisateur',
              '3.1 Création de Compte\n'
                  'Pour utiliser certaines fonctionnalités, vous devez créer un compte en '
                  'fournissant un numéro de téléphone valide et en complétant le processus '
                  'd\'inscription.\n\n'
                  '3.2 Sécurité du Compte\n'
                  'Vous êtes responsable de maintenir la confidentialité de vos identifiants '
                  'de connexion et de toutes les activités effectuées sous votre compte.\n\n'
                  '3.3 Information Exacte\n'
                  'Vous vous engagez à fournir des informations exactes, complètes et à jour '
                  'lors de votre inscription et à les maintenir à jour.',
            ),

            _buildSection(
              '4. Utilisation du Service',
              '4.1 Utilisation Autorisée\n'
                  'Vous acceptez d\'utiliser l\'application uniquement à des fins légales et '
                  'conformes aux présentes conditions.\n\n'
                  '4.2 Interdictions\n'
                  'Il est interdit de :\n'
                  '• Utiliser l\'application à des fins frauduleuses ou illégales\n'
                  '• Perturber ou tenter de perturber le fonctionnement de l\'application\n'
                  '• Copier, modifier ou distribuer le contenu de l\'application sans autorisation\n'
                  '• Utiliser des robots, scrapers ou autres moyens automatisés\n'
                  '• Publier du contenu offensant, diffamatoire ou illégal\n'
                  '• Se faire passer pour une autre personne ou entité',
            ),

            _buildSection(
              '5. Marketplace et Transactions',
              '5.1 Rôle d\'Intermédiaire\n'
                  'AgriSmart CI agit comme un intermédiaire entre les vendeurs et les acheteurs. '
                  'Nous ne sommes pas responsables de la qualité, de la sécurité ou de la '
                  'légalité des produits vendus.\n\n'
                  '5.2 Responsabilité des Utilisateurs\n'
                  'Les vendeurs sont responsables de la description exacte de leurs produits '
                  'et de leur conformité aux réglementations. Les acheteurs sont responsables '
                  'de vérifier la qualité des produits avant l\'achat.\n\n'
                  '5.3 Paiements\n'
                  'Les transactions financières sont traitées par des prestataires de paiement '
                  'tiers. AgriSmart CI ne stocke pas vos informations de paiement.',
            ),

            _buildSection(
              '6. Diagnostic IA et Conseils',
              '6.1 Nature du Service\n'
                  'Le service de diagnostic de maladies des cultures utilise l\'intelligence '
                  'artificielle et doit être considéré comme un outil d\'aide à la décision, '
                  'non comme un diagnostic définitif.\n\n'
                  '6.2 Limitations\n'
                  'Les diagnostics et conseils fournis sont basés sur des modèles '
                  'd\'apprentissage automatique et peuvent ne pas être précis à 100%. '
                  'En cas de doute, consultez un agronome professionnel.\n\n'
                  '6.3 Responsabilité\n'
                  'AgriSmart CI ne peut être tenu responsable des pertes résultant de '
                  'l\'utilisation des diagnostics ou conseils fournis par l\'application.',
            ),

            _buildSection(
              '7. Propriété Intellectuelle',
              'Tous les contenus de l\'application (textes, images, logos, code, etc.) '
                  'sont la propriété d\'AgriSmart CI ou de ses partenaires et sont protégés '
                  'par les lois sur la propriété intellectuelle.\n\n'
                  'Vous conservez tous les droits sur le contenu que vous publiez, mais vous '
                  'accordez à AgriSmart CI une licence d\'utilisation de ce contenu pour '
                  'fournir et améliorer nos services.',
            ),

            _buildSection(
              '8. Confidentialité et Données Personnelles',
              'La collecte et l\'utilisation de vos données personnelles sont régies par '
                  'notre Politique de Confidentialité, qui fait partie intégrante des présentes '
                  'conditions.\n\n'
                  'Nous nous engageons à protéger votre vie privée et à utiliser vos données '
                  'conformément aux lois ivoiriennes et internationales sur la protection des données.',
            ),

            _buildSection(
              '9. Limitation de Responsabilité',
              'AgriSmart CI ne peut être tenu responsable de :\n\n'
                  '• Tout dommage indirect, accessoire, spécial ou consécutif\n'
                  '• La perte de profits, de revenus ou de données\n'
                  '• L\'interruption du service ou l\'indisponibilité de l\'application\n'
                  '• Les erreurs ou inexactitudes du contenu\n'
                  '• Les actions des autres utilisateurs\n\n'
                  'Notre responsabilité totale ne dépassera pas le montant que vous avez '
                  'payé pour utiliser le service au cours des 12 derniers mois.',
            ),

            _buildSection(
              '10. Résiliation',
              'Nous nous réservons le droit de suspendre ou de résilier votre compte à '
                  'tout moment, sans préavis, en cas de violation des présentes conditions.\n\n'
                  'Vous pouvez également résilier votre compte à tout moment en nous contactant '
                  'via le service support. La résiliation n\'affecte pas les obligations déjà '
                  'contractées.',
            ),

            _buildSection(
              '11. Modifications des Conditions',
              'Nous nous réservons le droit de modifier ces conditions à tout moment. '
                  'Les modifications seront notifiées via l\'application et entreront en vigueur '
                  'dès leur publication.\n\n'
                  'Votre utilisation continue de l\'application après la publication des '
                  'modifications constitue votre acceptation des nouvelles conditions.',
            ),

            _buildSection(
              '12. Droit Applicable',
              'Ces conditions sont régies par les lois de la République de Côte d\'Ivoire. '
                  'Tout litige relatif à ces conditions sera soumis à la juridiction exclusive '
                  'des tribunaux ivoiriens.',
            ),

            _buildSection(
              '13. Contact',
              'Pour toute question concernant ces conditions d\'utilisation, contactez-nous :\n\n'
                  '📧 Email : legal@agrismart.ci\n'
                  '📞 Téléphone : +225 07 12 34 56 78\n'
                  '📍 Adresse : Abidjan, Côte d\'Ivoire\n\n'
                  'Support technique : support@agrismart.ci',
            ),

            const SizedBox(height: 32),

            // Bouton d'acceptation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'En créant un compte, vous acceptez ces conditions d\'utilisation.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bouton retour
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'J\'ai lu et compris',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}