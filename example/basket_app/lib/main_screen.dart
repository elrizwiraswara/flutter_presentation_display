import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_presentation_display/display.dart';
import 'package:flutter_presentation_display/flutter_presentation_display.dart';

class Product {
  final String name;
  final double price;
  final String imageUrl; 

  Product({
    required this.name,
    required this.price,
    required this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'imageUrl': imageUrl,
      };
}

/// Main Screen
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  FlutterPresentationDisplay displayManager = FlutterPresentationDisplay();
  List<Display?> displays = [];
  
  late AnimationController _addToCartController;
  late AnimationController _scaleController;
  late AnimationController _shakeController;

  final List<Product> products = [
    Product(
      name: 'Laptop',
      price: 999.99,
      imageUrl:
          'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=500',
    ),
    Product(
      name: 'Telefon',
      price: 699.99,
      imageUrl:
          'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=500',
    ),
    Product(
      name: 'Tablet',
      price: 299.99,
      imageUrl:
          'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=500',
    ),
    Product(
      name: 'Kulaklık',
      price: 79.99,
      imageUrl:
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500',
    ),
  ];

  List<Product> cartItems = [];

  dynamic dataFromPresentation;

  @override
  void initState() {
    super.initState();

    _addToCartController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    displayManager.connectedDisplaysChangedStream.listen((event) {
      debugPrint("connected displays changed: $event");
    });

    displayManager.listenDataFromPresentationDisplay(onDataReceived);
    
    Future.microtask(() async {
      final values = await displayManager.getDisplays();
      displays.clear();
      displays.addAll(values!);
      for (final display in displays) {
        if (display?.displayId == 1) {
          displayManager.showSecondaryDisplay(
              displayId: 2, routerName: "presentation");
        }
      }
    });
  }

  @override
  void dispose() {
    _addToCartController.dispose();
    _scaleController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void onDataReceived(dynamic data) {
    debugPrint('received data from presentation display: $data');
    setState(() {});
  }

  void addToCart(Product product) async {
 
    _addToCartController.forward(from: 0);
    _shakeController.forward(from: 0);

    setState(() {
      cartItems.add(product);
    });

    final cartData = cartItems.map((item) => item.toJson()).toList();
    debugPrint('Sending cart data: $cartData');

    try {
      final result = await displayManager.transferDataToPresentation(cartData);
      debugPrint('Transfer result: $result');
    } catch (e) {
      debugPrint('Transfer error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alışveriş Uygulaması'),
        backgroundColor: Colors.teal,
        elevation: 0,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      sin(_shakeController.value * 4 * pi) * 4,
                      0,
                    ),
                    child: child,
                  );
                },
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {},
                ),
              ),
              if (cartItems.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      '${cartItems.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return MouseRegion(
            onEnter: (_) => _scaleController.forward(),
            onExit: (_) => _scaleController.reverse(),
            child: AnimatedBuilder(
              animation: _scaleController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_scaleController.value * 0.05),
                  child: child,
                );
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Hero(
                        tag: 'product_${product.name}',
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${product.price} TL',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.teal.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ScaleTransition(
                              scale:
                                  Tween<double>(begin: 1.0, end: 0.95).animate(
                                CurvedAnimation(
                                  parent: _addToCartController,
                                  curve: Curves.easeInOut,
                                ),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () => addToCart(product),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(Icons.shopping_cart_outlined),
                                label: const Text('Sepete Ekle'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
