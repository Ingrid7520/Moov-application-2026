// lib/screens/products/edit_product_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/user_service.dart';

const String baseUrl = 'http://192.168.1.161:8001/api';

class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;

  late String _selectedQuality;
  late String _selectedStatus;
  bool _isLoading = false;

  final Map<String, String> _qualityGrades = {
    'A': 'Grade A (Premium)',
    'B': 'Grade B (Standard)',
    'C': 'Grade C (Économique)',
    'organic': 'Biologique',
  };

  final Map<String, String> _statuses = {
    'available': 'Disponible',
    'sold': 'Vendu',
    'reserved': 'Réservé',
  };

  @override
  void initState() {
    super.initState();
    // Initialiser avec les valeurs actuelles du produit
    _nameController = TextEditingController(text: widget.product['name']);
    _quantityController = TextEditingController(text: widget.product['quantity'].toString());
    _priceController = TextEditingController(text: widget.product['unit_price'].toString());
    _descriptionController = TextEditingController(text: widget.product['description'] ?? '');
    _selectedQuality = widget.product['quality_grade'] ?? 'B';
    _selectedStatus = widget.product['status'] ?? 'available';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await UserService.getToken();
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final updateData = {
        'name': _nameController.text.trim(),
        'quantity': double.parse(_quantityController.text),
        'unit_price': double.parse(_priceController.text),
        'description': _descriptionController.text.trim(),
        'quality_grade': _selectedQuality,
        'status': _selectedStatus,
      };

      print('📤 Mise à jour produit: $updateData');

      final response = await http.put(
        Uri.parse('$baseUrl/products/${widget.product['id']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(updateData),
      );

      print('📥 Status: ${response.statusCode}');
      print('📥 Response: ${response.body}');

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Produit mis à jour avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Retourner true pour recharger la liste
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Erreur lors de la mise à jour');
      }
    } catch (e) {
      print('❌ Erreur: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Modifier le produit'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Type de produit (non modifiable)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.category, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Type de produit',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getProductTypeLabel(widget.product['product_type']),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Nom du produit
            _buildTextField(
              controller: _nameController,
              label: 'Nom du produit',
              icon: Icons.inventory_2,
              hint: 'Ex: Cacao de qualité supérieure',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom est requis';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Quantité et Prix
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _quantityController,
                    label: 'Quantité (kg)',
                    icon: Icons.scale,
                    hint: '100',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requis';
                      }
                      final number = double.tryParse(value);
                      if (number == null || number <= 0) {
                        return 'Invalide';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _priceController,
                    label: 'Prix (FCFA/kg)',
                    icon: Icons.attach_money,
                    hint: '1500',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requis';
                      }
                      final number = double.tryParse(value);
                      if (number == null || number <= 0) {
                        return 'Invalide';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Qualité
            _buildDropdown(
              label: 'Qualité',
              icon: Icons.star,
              value: _selectedQuality,
              items: _qualityGrades,
              onChanged: (value) {
                setState(() => _selectedQuality = value!);
              },
            ),

            const SizedBox(height: 16),

            // Statut
            _buildDropdown(
              label: 'Statut',
              icon: Icons.check_circle,
              value: _selectedStatus,
              items: _statuses,
              onChanged: (value) {
                setState(() => _selectedStatus = value!);
              },
            ),

            const SizedBox(height: 16),

            // Description
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description (optionnel)',
                  hintText: 'Décrivez votre produit...',
                  prefixIcon: Icon(Icons.description, color: Colors.green[700]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Bouton de mise à jour
            ElevatedButton(
              onPressed: _isLoading ? null : _updateProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                'Enregistrer les modifications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.green[700]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required Map<String, String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),  // ← 16 → 12
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,  // ← AJOUTÉ
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13),  // ← AJOUTÉ
          prefixIcon: Icon(icon, color: Colors.green[700], size: 20),  // ← size 20
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),  // ← AJOUTÉ
        ),
        dropdownColor: Colors.white,
        items: items.entries.map((entry) {
          return DropdownMenuItem(
            value: entry.key,
            child: Text(
              entry.value,
              style: const TextStyle(fontSize: 13),  // ← AJOUTÉ
              overflow: TextOverflow.ellipsis,  // ← AJOUTÉ
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  String _getProductTypeLabel(String? type) {
    const labels = {
      'cocoa': 'Cacao',
      'cashew': 'Anacarde',
      'cassava': 'Manioc',
      'coffee': 'Café',
      'rice': 'Riz',
      'corn': 'Maïs',
      'vegetable': 'Légumes',
      'fruit': 'Fruits',
      'plantain': 'Banane plantain',
      'yams': 'Igname',
      'peanut': 'Arachide',
      'cotton': 'Coton',
      'other': 'Autre',
    };
    return labels[type] ?? type ?? 'Inconnu';
  }
}