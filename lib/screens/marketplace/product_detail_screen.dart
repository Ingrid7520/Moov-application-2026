// lib/screens/marketplace/product_detail_screen.dart
// ✅ VERSION AVEC AFFICHAGE IMAGES
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'payment_confirmation_screen.dart';
import '../../services/user_service.dart';
import '../../widgets/product_image_carousel.dart'; // ✅ NOUVEAU

const String baseUrl = 'http://192.168.1.161:8001/api';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  double _quantity = 1.0;
  String? _deliveryLocation;
  DateTime? _deliveryDate;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _deliveryLocation = widget.product['location'];
    _deliveryDate = DateTime.now().add(const Duration(days: 3));
  }

  double get _totalPrice => _quantity * widget.product['unit_price'];

  Future<void> _initiatePayment() async {
    setState(() => _isProcessing = true);

    try {
      final token = await UserService.getToken();
      final userId = await UserService.getUserId();

      if (token == null || userId == null) {
        throw Exception('Authentification requise');
      }

      final userData = await UserService.getUserData();

      final paymentData = {
        'product_id': widget.product['id'],
        'buyer_id': userId,
        'seller_id': widget.product['owner_id'],
        'quantity': _quantity,
        'unit_price': widget.product['unit_price'],
        'amount': _totalPrice,
        'buyer_phone': userData?['phone_number'] ?? '+225 0000000000',
        'delivery_location': _deliveryLocation ?? widget.product['location'],
        'delivery_date': (_deliveryDate ?? DateTime.now().add(const Duration(days: 3)))
            .toIso8601String(),
        'description': 'Achat de ${widget.product['name']}',
      };

      print('💳 Initiation paiement...');

      final response = await http.post(
        Uri.parse('$baseUrl/payment/initiate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(paymentData),
      );

      print('📥 Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        final transactionId = data['transaction_id'];
        final otpCode = data['otp_code'] ?? '123456';

        print('✅ Paiement initié - Transaction: $transactionId');

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentConfirmationScreen(
                transactionId: transactionId,
                otpCode: otpCode,
                amount: _totalPrice,
                productName: widget.product['name'],
                quantity: _quantity,
                deliveryDate: _deliveryDate,
                deliveryLocation: _deliveryLocation,
              ),
            ),
          ).then((success) {
            if (success == true) {
              Navigator.pop(context, true);
            }
          });
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Erreur');
      }
    } catch (e) {
      print('❌ Erreur: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _selectDeliveryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate ?? DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.green[700]!),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _deliveryDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxQuantity = widget.product['quantity'].toDouble();
    // ✅ RÉCUPÉRER LES IMAGES DU PRODUIT
    final List<String> productImages = (widget.product['images'] as List<dynamic>?)
        ?.map((img) => img.toString())
        .toList() ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: () {
              // TODO: Partager le produit
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ CARROUSEL D'IMAGES AU LIEU DU PLACEHOLDER
                  ProductImageCarousel(
                    images: productImages,
                    productType: widget.product['product_type'],
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.product['name'] ?? 'Sans nom',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getQualityLabel(widget.product['quality_grade']),
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Text(
                          '${widget.product['unit_price']} FCFA / kg',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Informations vendeur
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.green[100],
                                child: Icon(Icons.person, color: Colors.green[700]),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Vendu par',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      widget.product['owner_name'] ?? 'Vendeur',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.phone, color: Colors.green[700]),
                                onPressed: () {
                                  // TODO: Appeler le vendeur
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        _buildDetailRow(
                          Icons.inventory_2,
                          'Stock disponible',
                          '${widget.product['quantity']} kg',
                        ),
                        _buildDetailRow(
                          Icons.location_on,
                          'Localisation',
                          widget.product['location'] ?? 'Non spécifié',
                        ),

                        if (widget.product['description'] != null &&
                            widget.product['description'].toString().isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.product['description'],
                            style: TextStyle(
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        const Text(
                          'Quantité (kg)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (_quantity > 1) {
                                  setState(() => _quantity -= 1);
                                }
                              },
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Colors.green[700],
                              iconSize: 32,
                            ),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$_quantity kg',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                if (_quantity < maxQuantity) {
                                  setState(() => _quantity += 1);
                                }
                              },
                              icon: const Icon(Icons.add_circle_outline),
                              color: Colors.green[700],
                              iconSize: 32,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'Détails de livraison',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          leading: Icon(Icons.location_on, color: Colors.green[700]),
                          title: const Text('Lieu de récupération'),
                          subtitle: Text(_deliveryLocation ?? 'Non défini'),
                          trailing: const Icon(Icons.edit),
                          tileColor: Colors.grey[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onTap: () {
                            // TODO: Modifier le lieu
                          },
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          leading: Icon(Icons.calendar_today, color: Colors.green[700]),
                          title: const Text('Date de livraison'),
                          subtitle: Text(
                            _deliveryDate != null
                                ? '${_deliveryDate!.day}/${_deliveryDate!.month}/${_deliveryDate!.year}'
                                : 'Non défini',
                          ),
                          trailing: const Icon(Icons.edit),
                          tileColor: Colors.grey[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onTap: _selectDeliveryDate,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Barre d'achat fixe en bas
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '${_totalPrice.toStringAsFixed(0)} FCFA',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _initiatePayment,
                    icon: _isProcessing
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(Icons.shopping_cart_checkout, size: 24),
                    label: Text(
                      _isProcessing ? 'Traitement...' : 'Acheter maintenant',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getQualityLabel(String? grade) {
    const labels = {
      'A': 'Premium',
      'B': 'Standard',
      'C': 'Économique',
      'organic': 'Bio',
    };
    return labels[grade] ?? 'Standard';
  }
}