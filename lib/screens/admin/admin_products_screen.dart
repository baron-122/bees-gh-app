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
      builder: (_) => AlertDialog(
        title: const Text("Delete Product?"),
        content: const Text("Are you sure you want to delete this product?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
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
      builder: (_) => AlertDialog(
        title: const Text("Add Product"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name of Product"),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: "Unit Price"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
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
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
    const valueStyle = TextStyle(fontSize: 16);

    return Scaffold(
      appBar: AppBar(title: const Text("Products Page"), automaticallyImplyLeading: false,),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🟡 All Products Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    /// Title & Add
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("All Products", style: titleStyle),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add_circle),
                              onPressed: () => _showAddProductDialog(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    /// Product List
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
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            /// 🟢 Available Products Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Available Products", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    buildAvailableProductsCard(),
                  ],
                ),
              ),
            ),
          ],
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
              title: Text(e.key, style: const TextStyle(fontSize: 16)),
              trailing: Text("${e.value} kg", style: const TextStyle(fontSize: 16)),
            ),
          ).toList(),
        );
      },
    );
  }

}
