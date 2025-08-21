/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'order_confirmation_screen.dart';

class ShoppingCartScreen extends StatefulWidget {
  const ShoppingCartScreen({super.key});

  @override
  State<ShoppingCartScreen> createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen> {
  List<String> selectedCartItems = [];
  double totalPrice = 0.0;
  int _selectedIndex = 1; // Cart tab
  List<QueryDocumentSnapshot> cartDocs = []; // <- holds latest docs

  Stream<QuerySnapshot> getCartStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('shopping_cart')
        .where('user_id', isEqualTo: userId)
        .orderBy('added_at', descending: true)
        .snapshots();
  }

  void toggleSelection(String docId, double subtotal) {
    setState(() {
      if (selectedCartItems.contains(docId)) {
        selectedCartItems.remove(docId);
        totalPrice -= subtotal;
      } else {
        selectedCartItems.add(docId);
        totalPrice += subtotal;
      }
    });
  }

  void cancelAllSelections() {
    setState(() {
      selectedCartItems.clear();
      totalPrice = 0.0;
    });
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);

    if (index == 0) {
      Navigator.pushNamed(context, '/client_home');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/settings');
    }
  }

  void proceedToCheckout() {
    final selectedProducts = cartDocs
        .where((doc) => selectedCartItems.contains(doc.id))
        .map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'product_id': doc.id,
        'product_name': data['product_name'],
        'quantity': data['quantity'],
        'unit_price': data['unit_price'],
        'subtotal': data['subtotal'],
        'image_url': data['image_url'],
      };
    }).toList();

    final currentUser = FirebaseAuth.instance.currentUser;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderConfirmationScreen(
          selectedProducts: selectedProducts,
          userDetails: {
            'user_id': currentUser?.uid,
            'name': currentUser?.displayName ?? '',
            'email': currentUser?.email ?? '',
            'phone': currentUser?.phoneNumber ?? '',
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "Shopping Cart",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: getCartStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  cartDocs = snapshot.data!.docs;

                  if (cartDocs.isEmpty) return const Center(child: Text("🛒 Your cart is empty."));

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: cartDocs.length,
                    itemBuilder: (context, index) {
                      final doc = cartDocs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final docId = doc.id;
                      final isSelected = selectedCartItems.contains(docId);
                      final subtotal = (data['subtotal'] ?? 0).toDouble();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              data['image_url'] ?? '',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(data['product_name'] ?? 'Unknown'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Qty: ${data['quantity']}"),
                              Text("Unit: GHS ${data['unit_price']?.toStringAsFixed(2)}"),
                              Text("Subtotal: GHS ${subtotal.toStringAsFixed(2)}"),
                            ],
                          ),
                          trailing: Checkbox(
                            shape: const CircleBorder(),
                            value: isSelected,
                            onChanged: (_) => toggleSelection(docId, subtotal),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Card(
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      /// Cancel All Checkbox
                      Row(
                        children: [
                          Checkbox(
                            shape: const CircleBorder(),
                            value: selectedCartItems.length == cartDocs.length && cartDocs.isNotEmpty,
                            onChanged: (_) {
                              setState(() {
                                if (selectedCartItems.length == cartDocs.length) {
                                  selectedCartItems.clear();
                                  totalPrice = 0.0;
                                } else {
                                  selectedCartItems = cartDocs.map((d) => d.id).toList();
                                  totalPrice = cartDocs.fold(0.0, (sum, doc) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    return sum + (data['subtotal'] ?? 0).toDouble();
                                  });
                                }
                              });
                            },
                          ),
                          const Text("Cancel All"),
                        ],
                      ),

                      /// Total + Checkout
                      Row(
                        children: [
                          Text(
                            "Total: GHS ${totalPrice.toStringAsFixed(2)}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: selectedCartItems.isEmpty ? null : proceedToCheckout,
                            child: const Text("Checkout"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'order_confirmation_screen.dart';

class ShoppingCartScreen extends StatefulWidget {
  const ShoppingCartScreen({super.key});

  @override
  State<ShoppingCartScreen> createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen> {
  List<String> selectedCartItems = [];
  double totalPrice = 0.0;
  List<QueryDocumentSnapshot> cartDocs = [];

  Stream<QuerySnapshot> getCartStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('shopping_cart')
        .where('user_id', isEqualTo: userId)
        .orderBy('added_at', descending: true)
        .snapshots();
  }

  void toggleSelection(String docId, double subtotal) {
    setState(() {
      if (selectedCartItems.contains(docId)) {
        selectedCartItems.remove(docId);
        totalPrice -= subtotal;
      } else {
        selectedCartItems.add(docId);
        totalPrice += subtotal;
      }
    });
  }

  void proceedToCheckout() {
    final selectedProducts = cartDocs
        .where((doc) => selectedCartItems.contains(doc.id))
        .map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'product_id': doc.id,
        'product_name': data['product_name'],
        'quantity': data['quantity'],
        'unit_price': data['unit_price'],
        'subtotal': data['subtotal'],
        'image_url': data['image_url'],
      };
    }).toList();

    final currentUser = FirebaseAuth.instance.currentUser;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderConfirmationScreen(
          selectedProducts: selectedProducts,
          userDetails: {
            'user_id': currentUser?.uid,
            'name': currentUser?.displayName ?? '',
            'email': currentUser?.email ?? '',
            'phone': currentUser?.phoneNumber ?? '',
          },
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Shopping Cart",
          style: TextStyle(
            color: Color(0xFFFFD54F), // gold
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.brown[800],
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFFFD54F)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.shade50,
              Colors.amber.shade100,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: getCartStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    cartDocs = snapshot.data!.docs;

                    if (cartDocs.isEmpty) {
                      return const Center(
                        child: Text(
                          "🛒 Your cart is empty",
                          style: TextStyle(fontSize: 23),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: cartDocs.length,
                      itemBuilder: (context, index) {
                        final doc = cartDocs[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final docId = doc.id;
                        final isSelected = selectedCartItems.contains(docId);
                        final subtotal = (data['subtotal'] ?? 0).toDouble();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _glassCard(
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  data['image_url'] ?? '',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image, size: 32),
                                  ),
                                ),
                              ),
                              title: Text(
                                data['product_name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Qty: ${data['quantity']}"),
                                  Text("Unit: GHS ${data['unit_price']?.toStringAsFixed(2)}"),
                                  Text("Subtotal: GHS ${subtotal.toStringAsFixed(2)}"),
                                ],
                              ),
                              trailing: Checkbox(
                                shape: const CircleBorder(),
                                value: isSelected,
                                onChanged: (_) => toggleSelection(docId, subtotal),
                                activeColor: Colors.brown[800],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Bottom bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, -2),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Cancel All
                    Row(
                      children: [
                        Checkbox(
                          shape: const CircleBorder(),
                          activeColor: Colors.brown[800],
                          value: selectedCartItems.length == cartDocs.length &&
                              cartDocs.isNotEmpty,
                          onChanged: (_) {
                            setState(() {
                              if (selectedCartItems.length == cartDocs.length) {
                                selectedCartItems.clear();
                                totalPrice = 0.0;
                              } else {
                                selectedCartItems =
                                    cartDocs.map((d) => d.id).toList();
                                totalPrice = cartDocs.fold(0.0, (sum, doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  return sum +
                                      (data['subtotal'] ?? 0).toDouble();
                                });
                              }
                            });
                          },
                        ),
                        const Text("Cancel All"),
                      ],
                    ),

                    // Total + Checkout
                    Row(
                      children: [
                        Text(
                          "Total: GHS ${totalPrice.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown[800],
                            foregroundColor: const Color(0xFFFFD54F),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: selectedCartItems.isEmpty
                              ? null
                              : proceedToCheckout,
                          child: const Text(
                            "Checkout",
                            style: TextStyle(fontWeight: FontWeight.bold),
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
      ),
    );
  }
}
