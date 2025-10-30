import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_presentation_display/flutter_presentation_display.dart';

/// UI of Presentation display
class PresentationScreen extends StatefulWidget {
  const PresentationScreen({super.key});

  @override
  _PresentationScreenState createState() => _PresentationScreenState();
}

class _PresentationScreenState extends State<PresentationScreen>
    with TickerProviderStateMixin {
  FlutterPresentationDisplay displayManager = FlutterPresentationDisplay();
  List<Map<String, dynamic>> cartItems = [];

  late AnimationController _slideController;
  final List<AnimationController> _itemControllers = [];

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    displayManager.listenDataFromMainDisplay((data) {
      debugPrint('Received data in presentation: $data');
      try {
        if (data is List) {
          final oldLength = cartItems.length;
          setState(() {
            cartItems = (data).map<Map<String, dynamic>>((item) {
              return Map<String, dynamic>.from(item);
            }).toList();

           
            while (_itemControllers.length < cartItems.length) {
              _itemControllers.add(
                AnimationController(
                  duration: const Duration(milliseconds: 500),
                  vsync: this,
                )..forward(),
              );
            }
          });

          if (cartItems.length > oldLength) {
            _slideController.forward(from: 0);
          }
        } else if (data is String) {
          final decodedData = jsonDecode(data) as List;
          setState(() {
            cartItems = decodedData.map<Map<String, dynamic>>((item) {
              return Map<String, dynamic>.from(item);
            }).toList();
          });
        }
      } catch (e) {
        debugPrint('Error parsing data: $e');
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  double get totalPrice {
    return cartItems.fold(0, (sum, item) => sum + (item['price'] as double));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sepetim'),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: cartItems.isEmpty
                ? AnimatedBuilder(
                    animation: _slideController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 50 * (1 - _slideController.value)),
                        child: Opacity(
                          opacity: _slideController.value,
                          child: child,
                        ),
                      );
                    },
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Sepetiniz boş',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      final itemAnimation = _itemControllers[index];

                      return AnimatedBuilder(
                        animation: itemAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              -200 * (1 - itemAnimation.value),
                              0,
                            ),
                            child: Opacity(
                              opacity: itemAnimation.value,
                              child: child,
                            ),
                          );
                        },
                        child: Hero(
                          tag: 'product_${item['name']}',
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item['imageUrl'] as String,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: Text(
                                item['name'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${item['price']} TL',
                                style: TextStyle(
                                  color: Colors.teal.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          AnimatedBuilder(
            animation: _slideController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 50 * (1 - _slideController.value)),
                child: Opacity(
                  opacity: _slideController.value,
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Toplam Tutar:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${totalPrice.toStringAsFixed(2)} TL',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
