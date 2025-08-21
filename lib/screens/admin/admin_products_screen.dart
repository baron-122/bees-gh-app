import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  Stream<QuerySnapshot> getAllProducts() {
    return FirebaseFirestore.instance.collection('products').snapshots();
  }

  Stream<QuerySnapshot> getAvailableProducts() {
    return FirebaseFirestore.instance.collection('bee_transactions').snapshots();
  }

  Future<void> _deleteProduct(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.6)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Delete Product?",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Are you sure you want to delete this product?",
                    style: TextStyle(color: Colors.brown),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Delete", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('products').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product deleted")),
      );
    }
  }

  Future<void> _showAddProductDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white.withOpacity(0.1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Add Product", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Name of Product"),
                  ),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: "Unit Price"),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final price = double.tryParse(priceController.text.trim());

                          if (name.isEmpty || price == null) return;

                          final existing = await FirebaseFirestore.instance
                              .collection('products')
                              .where('name', isEqualTo: name)
                              .get();

                          if (existing.docs.isNotEmpty) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("🚫 Product already added")),
                            );
                            return;
                          }

                          await FirebaseFirestore.instance.collection('products').add({
                            'name': name,
                            'unit_price': price,
                            'created_at': FieldValue.serverTimestamp(),
                          });

                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("✅ Product added")),
                          );
                        },
                        child: const Text("Add", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown);
    const valueStyle = TextStyle(fontSize: 16, color: Colors.brown);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Products Page",
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
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.amber.shade50,
                Colors.amber.shade100,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
        ),
       child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// All Products Card
            _buildGlassyCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("All Products", style: titleStyle),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.brown),
                        onPressed: () => _showAddProductDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: getAllProducts(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      final docs = snapshot.data!.docs;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text(data['name'] ?? '', style: valueStyle),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("GHS ${data['unit_price']}", style: valueStyle),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _deleteProduct(context, doc.id),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            /// Available Products Card
            _buildGlassyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Available Products", style: titleStyle),
                  const SizedBox(height: 12),
                  buildAvailableProductsCard(),
                ],
              ),
            ),
          ],
        ),
      ),
      )
    );
  }

  Widget _buildGlassyCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget buildAvailableProductsCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: getAvailableProducts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final Map<String, double> productQuantities = {};
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['product'] ?? 'Unknown';
          final qty = (data['quantity'] ?? 0).toDouble();
          productQuantities[name] = (productQuantities[name] ?? 0) + qty;
        }

        return Column(
          children: productQuantities.entries.map(
                (e) => ListTile(
              title: Text(e.key, style: const TextStyle(fontSize: 16, color: Colors.brown)),
              trailing: Text("${e.value} kg", style: const TextStyle(fontSize: 16, color: Colors.brown)),
            ),
          ).toList(),
        );
      },
    );
  }
}

