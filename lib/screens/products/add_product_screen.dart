// lib/screens/products/add_product_screen.dart
// ✅ VERSION AVEC UPLOAD IMAGES
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/user_service.dart';
import '../../widgets/image_picker_widget.dart';

const String baseUrl = 'http://192.168.1.161:8001/api';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = 'cocoa';
  String _selectedQuality = 'B';
  List<String> _selectedImages = []; // ✅ NOUVEAU
  bool _isLoading = false;

  final Map<String, String> _productTypes = {
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

  final Map<String, String> _qualityGrades = {
    'A': 'Grade A (Premium)',
    'B': 'Grade B (Standard)',
    'C': 'Grade C (Économique)',
    'organic': 'Biologique',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await UserService.getToken();
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final productData = {
        'name': _nameController.text.trim(),
        'product_type': _selectedType,
        'quantity': double.parse(_quantityController.text),
        'unit_price': double.parse(_priceController.text),
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'quality_grade': _selectedQuality,
        'harvest_date': DateTime.now().toIso8601String(),
        'images': _selectedImages, // ✅ NOUVEAU: Envoyer images base64
      };

      print('📤 Envoi produit avec ${_selectedImages.length} image(s)');

      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(productData),
      );

      print('📥 Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Produit ajouté avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Erreur lors de l\'ajout');
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
        title: const Text('Ajouter un produit'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // ✅ WIDGET SÉLECTION IMAGES
            ImagePickerWidget(
              initialImages: _selectedImages,
              onImagesChanged: (images) {
                setState(() {
                  _selectedImages = images;
                });
                print('📸 ${images.length} image(s) sélectionnée(s)');
              },
              maxImages: 5,
            ),

            const SizedBox(height: 24),
            const Divider(),
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
                if (value.trim().length < 2) {
                  return 'Le nom doit contenir au moins 2 caractères';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Type de produit
            _buildDropdown(
              label: 'Type de produit',
              icon: Icons.category,
              value: _selectedType,
              items: _productTypes,
              onChanged: (value) {
                setState(() => _selectedType = value!);
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

            // Localisation
            _buildTextField(
              controller: _locationController,
              label: 'Localisation',
              icon: Icons.location_on,
              hint: 'Ex: Abidjan, Cocody',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La localisation est requise';
                }
                return null;
              },
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

            // Bouton de soumission
            ElevatedButton(
              onPressed: _isLoading ? null : _submitProduct,
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
                'Ajouter le produit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Aide
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ajoutez des photos pour attirer plus d\'acheteurs. Max 5 photos, 5MB chacune.',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 13,
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.green[700]),
          border: InputBorder.none,
        ),
        dropdownColor: Colors.white,
        items: items.entries.map((entry) {
          return DropdownMenuItem(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}