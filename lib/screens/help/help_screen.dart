// lib/screens/help/help_screen.dart
/// 📖 Page d'Aide - Guide complet pour l'utilisateur
/// Accessible depuis ProfileScreen

import 'package:flutter/material.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  String? _expandedSection;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Aide'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // En-tête avec illustration
            _buildHeader(),

            const SizedBox(height: 16),

            // Barre de recherche
            _buildSearchBar(),

            const SizedBox(height: 24),

            // Sections d'aide
            _buildHelpSection(
              'Premiers Pas',
              Icons.rocket_launch,
              Colors.blue,
              [
                _HelpItem(
                  'Comment créer un compte ?',
                  'Cliquez sur "S\'inscrire" depuis l\'écran de connexion, '
                      'entrez votre numéro de téléphone et suivez les instructions. '
                      'Vous recevrez un code par SMS à valider.',
                ),
                _HelpItem(
                  'Comment me connecter ?',
                  'Entrez votre numéro de téléphone sur l\'écran de connexion, '
                      'puis saisissez le code OTP reçu par SMS.',
                ),
                _HelpItem(
                  'Comment choisir mon rôle ?',
                  'Lors de l\'inscription, vous pouvez choisir d\'être Acheteur, '
                      'Producteur, ou les deux. Ce choix détermine les fonctionnalités '
                      'disponibles dans l\'application.',
                ),
              ],
            ),

            _buildHelpSection(
              'Diagnostic de Culture',
              Icons.camera_alt,
              Colors.orange,
              [
                _HelpItem(
                  'Comment diagnostiquer une plante ?',
                  '1. Allez dans l\'onglet "Diagnostic"\n'
                      '2. Prenez une photo claire de la plante malade\n'
                      '3. L\'IA analysera automatiquement l\'image\n'
                      '4. Consultez le diagnostic et les recommandations',
                ),
                _HelpItem(
                  'Quel type de photo prendre ?',
                  'Prenez une photo nette et bien éclairée montrant clairement '
                      'les symptômes. Évitez les photos floues ou trop sombres. '
                      'Rapprochez-vous de la zone affectée.',
                ),
                _HelpItem(
                  'Que faire après le diagnostic ?',
                  'Suivez les conseils donnés par l\'application. Si nécessaire, '
                      'contactez un expert agricole via le bouton "Contacter Expert".',
                ),
              ],
            ),

            _buildHelpSection(
              'Chat avec AgriBot',
              Icons.chat_bubble,
              Colors.green,
              [
                _HelpItem(
                  'Comment utiliser le chat ?',
                  'Allez dans l\'onglet "Chat" et posez vos questions sur '
                      'l\'agriculture, les cultures, les maladies des plantes, etc. '
                      'AgriBot vous répondra instantanément.',
                ),
                _HelpItem(
                  'Puis-je envoyer des images ?',
                  'Oui ! Cliquez sur l\'icône caméra pour prendre une photo ou '
                      'l\'icône galerie pour sélectionner une image. AgriBot peut '
                      'analyser les images de plantes.',
                ),
                _HelpItem(
                  'Comment consulter l\'historique ?',
                  'Cliquez sur l\'icône horloge en haut du chat pour voir toutes '
                      'vos conversations passées avec AgriBot.',
                ),
              ],
            ),

            _buildHelpSection(
              'Météo Agricole',
              Icons.wb_sunny,
              Colors.amber,
              [
                _HelpItem(
                  'Comment voir la météo ?',
                  'La météo s\'affiche automatiquement sur l\'écran d\'accueil. '
                      'Elle est basée sur votre localisation enregistrée.',
                ),
                _HelpItem(
                  'Que signifient les conseils agricoles ?',
                  'Les conseils sont adaptés aux conditions météo actuelles et '
                      'vous aident à planifier vos activités agricoles (irrigation, '
                      'traitement, récolte, etc.).',
                ),
                _HelpItem(
                  'Comment voir les prévisions détaillées ?',
                  'Cliquez sur la carte météo de l\'accueil pour voir les '
                      'prévisions sur 5 jours avec des conseils détaillés.',
                ),
              ],
            ),

            _buildHelpSection(
              'Marketplace & Transactions',
              Icons.shopping_cart,
              Colors.purple,
              [
                _HelpItem(
                  'Comment acheter des produits ?',
                  'Allez dans "Achats", parcourez les produits disponibles, '
                      'cliquez sur celui qui vous intéresse et suivez le processus '
                      'd\'achat.',
                ),
                _HelpItem(
                  'Comment vendre mes produits ? (Producteurs)',
                  'Dans l\'onglet "Marchés", vous pouvez ajouter vos produits, '
                      'fixer les prix et gérer vos ventes.',
                ),
                _HelpItem(
                  'Quels sont les moyens de paiement ?',
                  'AgriSmart CI prend en charge Mobile Money (MTN, Moov, Orange), '
                      'Wave, et les virements bancaires.',
                ),
              ],
            ),

            _buildHelpSection(
              'Mon Profil',
              Icons.person,
              Colors.teal,
              [
                _HelpItem(
                  'Comment modifier mes informations ?',
                  'Allez dans "Profil", cliquez sur "Modifier le profil" et '
                      'mettez à jour vos informations (nom, localisation, etc.).',
                ),
                _HelpItem(
                  'Comment changer ma photo de profil ?',
                  'Dans votre profil, cliquez sur l\'avatar pour télécharger '
                      'une nouvelle photo depuis votre galerie.',
                ),
                _HelpItem(
                  'Comment me déconnecter ?',
                  'Allez dans "Profil" et cliquez sur "Déconnexion" en bas de '
                      'la page.',
                ),
              ],
            ),

            _buildHelpSection(
              'Sécurité & Confidentialité',
              Icons.security,
              Colors.red,
              [
                _HelpItem(
                  'Mes données sont-elles sécurisées ?',
                  'Oui, toutes vos données sont chiffrées et stockées de manière '
                      'sécurisée. Nous ne partageons jamais vos informations sans '
                      'votre consentement.',
                ),
                _HelpItem(
                  'Comment signaler un problème ?',
                  'Utilisez le bouton "Signaler" dans l\'application ou '
                      'contactez-nous via Support & Service Client.',
                ),
                _HelpItem(
                  'Comment supprimer mon compte ?',
                  'Contactez notre service client via le menu Aide. Nous '
                      'traiterons votre demande dans les 48h.',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Besoin d'aide supplémentaire
            _buildContactCard(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[600]!, Colors.green[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.help_outline,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Comment pouvons-nous vous aider ?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Trouvez des réponses à vos questions',
            style: TextStyle(
              color: Colors.green[100],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Rechercher dans l\'aide...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(Icons.search, color: Colors.green[700]),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
          onChanged: (value) {
            // TODO: Implémenter la recherche
          },
        ),
      ),
    );
  }

  Widget _buildHelpSection(
      String title,
      IconData icon,
      Color color,
      List<_HelpItem> items,
      ) {
    final isExpanded = _expandedSection == title;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _expandedSection = isExpanded ? null : title;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded) ...[
              const Divider(height: 1),
              ...items.map((item) => _buildHelpItemTile(item, color)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItemTile(_HelpItem item, Color color) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(Icons.help_outline, color: color, size: 20),
      title: Text(
        item.question,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            item.answer,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green[50]!, Colors.green[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.support_agent, size: 48, color: Colors.green[700]),
            const SizedBox(height: 16),
            const Text(
              'Besoin d\'aide supplémentaire ?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Notre équipe est là pour vous aider',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/support');
              },
              icon: const Icon(Icons.headset_mic),
              label: const Text('Contacter le Support'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpItem {
  final String question;
  final String answer;

  _HelpItem(this.question, this.answer);
}