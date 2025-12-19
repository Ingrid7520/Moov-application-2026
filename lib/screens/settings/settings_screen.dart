// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../auth/auth_screens.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = false;
  bool _smsNotifications = true;
  String _language = 'Français';
  String _currency = 'FCFA';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Paramètres'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section Notifications
          _buildSectionTitle('Notifications'),
          _buildCard([
            _buildSwitchTile(
              'Activer les notifications',
              'Recevoir des notifications push',
              _notificationsEnabled,
                  (value) => setState(() => _notificationsEnabled = value),
              Icons.notifications_active,
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              'Notifications email',
              'Recevoir des emails',
              _emailNotifications,
                  (value) => setState(() => _emailNotifications = value),
              Icons.email,
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              'Notifications SMS',
              'Recevoir des SMS',
              _smsNotifications,
                  (value) => setState(() => _smsNotifications = value),
              Icons.sms,
            ),
          ]),

          const SizedBox(height: 20),

          // Section Préférences
          _buildSectionTitle('Préférences'),
          _buildCard([
            _buildSelectTile(
              'Langue',
              _language,
              Icons.language,
                  () => _showLanguageDialog(),
            ),
            const Divider(height: 1),
            _buildSelectTile(
              'Devise',
              _currency,
              Icons.attach_money,
                  () => _showCurrencyDialog(),
            ),
          ]),

          const SizedBox(height: 20),

          // Section Compte
          _buildSectionTitle('Compte'),
          _buildCard([
            _buildActionTile(
              'Modifier le profil',
              'Changer vos informations',
              Icons.edit,
                  () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité bientôt disponible')),
                );
              },
            ),
            const Divider(height: 1),
            _buildActionTile(
              'Changer le mot de passe',
              'Modifier votre code secret',
              Icons.lock,
                  () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité bientôt disponible')),
                );
              },
            ),
            const Divider(height: 1),
            _buildActionTile(
              'Supprimer le compte',
              'Supprimer définitivement',
              Icons.delete_forever,
                  () => _showDeleteDialog(),
              textColor: Colors.red,
            ),
          ]),

          const SizedBox(height: 20),

          // Section À propos
          _buildSectionTitle('À propos'),
          _buildCard([
            _buildInfoTile('Version', '1.0.0', Icons.info),
            const Divider(height: 1),
            _buildActionTile(
              'Conditions d\'utilisation',
              'Consulter les CGU',
              Icons.description,
                  () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité bientôt disponible')),
                );
              },
            ),
          ]),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged, IconData icon) {
    return SwitchListTile(
      secondary: Icon(icon, color: Colors.green[700]),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      value: value,
      activeColor: Colors.green[700],
      onChanged: onChanged,
    );
  }

  Widget _buildSelectTile(String title, String value, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.green[700]),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap, {Color? textColor}) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.green[700]),
      title: Text(
        title,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
      ),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.green[700]),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      trailing: Text(value, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir la langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Français', 'English'].map((lang) {
            return RadioListTile<String>(
              title: Text(lang),
              value: lang,
              groupValue: _language,
              activeColor: Colors.green[700],
              onChanged: (value) {
                setState(() => _language = value!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir la devise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['FCFA', 'USD', 'EUR'].map((curr) {
            return RadioListTile<String>(
              title: Text(curr),
              value: curr,
              groupValue: _currency,
              activeColor: Colors.green[700],
              onChanged: (value) {
                setState(() => _currency = value!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text('Êtes-vous sûr de vouloir supprimer définitivement votre compte ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité bientôt disponible'), backgroundColor: Colors.red),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}