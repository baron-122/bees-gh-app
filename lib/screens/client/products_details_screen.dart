import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late List<String> imageUrls;
  int selectedImageIndex = 0;

  @override
  void initState() {
    super.initState();
    imageUrls = List<String>.from(widget.product['image_urls'] ?? []);
  }

  void _openFullImageViewer(int startIndex) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        int currentIndex = startIndex;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.black87,
              insetPadding: EdgeInsets.zero,
              child: Stack(
                children: [
                  Center(
                    child: Image.network(
                      imageUrls[currentIndex],
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 20,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  if (imageUrls.length > 1)
                    Positioned(
                      bottom: 40,
                      right: 20,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.9),
                        ),
                        onPressed: () {
                          setDialogState(() {
                            currentIndex = (currentIndex + 1) % imageUrls.length;
                          });
                        },
                        child: const Icon(Icons.arrow_forward_ios),
                      ),
                    )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showOrderDialog() {
    final sizes = List<Map<String, dynamic>>.from(widget.product['sizes'] ?? []);
    final hasSizeOptions = sizes.any((s) => s['size'] != null);

    int? selectedSizeIndex;
    double unitPrice = 0;
    String selectedSize = '';
    final quantityController = TextEditingController();
    final unitPriceController = TextEditingController();
    final totalCostController = TextEditingController();

    void updateCosts(StateSetter setState) {
      if (hasSizeOptions && selectedSizeIndex != null) {
        unitPrice = (sizes[selectedSizeIndex!]['price'] ?? 0).toDouble();
        selectedSize = sizes[selectedSizeIndex!]['size'].toString();
      } else if (!hasSizeOptions && sizes.isNotEmpty) {
        unitPrice = (sizes.first['price'] ?? 0).toDouble();
        selectedSize = '';
      }
      unitPriceController.text = unitPrice.toStringAsFixed(2);

      final quantity = int.tryParse(quantityController.text) ?? 0;
      final totalCost = quantity * unitPrice;
      totalCostController.text = totalCost.toStringAsFixed(2);
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            updateCosts(setState);

            return AlertDialog(
              title: const Text("Order Product"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasSizeOptions)
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(labelText: "Please select a Size"),
                        value: selectedSizeIndex,
                        items: List.generate(sizes.length, (index) {
                          final sizeLabel = sizes[index]['size']?.toString() ?? "N/A";
                          return DropdownMenuItem(
                            value: index,
                            child: Text("$sizeLabel g"),
                          );
                        }),
                        onChanged: (val) {
                          setState(() {
                            selectedSizeIndex = val;
                            updateCosts(setState);
                          });
                        },
                      ),
                    const SizedBox(height: 10),
                    TextFormField(
                      readOnly: true,
                      controller: unitPriceController,
                      decoration: const InputDecoration(
                        labelText: "Unit Price",
                        prefixText: "GHS ",
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: quantityController,
                      decoration: const InputDecoration(
                        labelText: "Quantity",
                        hintText: "Please enter quantity",
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => updateCosts(setState),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      readOnly: true,
                      controller: totalCostController,
                      decoration: const InputDecoration(
                        labelText: "Total Cost",
                        prefixText: "GHS ",
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final userId = FirebaseAuth.instance.currentUser?.uid;
                    if (userId == null) return;

                    final quantity = int.tryParse(quantityController.text) ?? 0;
                    final subtotal = quantity * unitPrice;

                    final cartItem = {
                      'user_id': userId,
                      'product_name': widget.product['name'],
                      'product_id': widget.product['id'] ?? '',
                      'image_url': imageUrls[selectedImageIndex],
                      'unit_price': unitPrice,
                      'quantity': quantity,
                      'subtotal': subtotal,
                      'size': selectedSize,
                      'added_at': FieldValue.serverTimestamp(),
                    };

                    await FirebaseFirestore.instance.collection('shopping_cart').add(cartItem);

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("✅ Product added to cart")),
                    );
                  },
                  child: const Text("Add to Cart"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = imageUrls.isNotEmpty;
    final selectedImage = hasImages ? imageUrls[selectedImageIndex] : null;
    final sizes = List<Map<String, dynamic>>.from(widget.product['sizes'] ?? []);
    final hasSizeOptions = sizes.any((s) => s['size'] != null);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product['name'] ?? 'Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedImage != null)
              GestureDetector(
                onTap: () => _openFullImageViewer(selectedImageIndex),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    selectedImage,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (imageUrls.length > 1)
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedImageIndex = index);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selectedImageIndex == index
                                ? Colors.amber
                                : Colors.grey,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrls[index],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            if (widget.product['category'] != null)
              Chip(
                label: Text(widget.product['category']),
                backgroundColor: Colors.amber[100],
              ),
            const SizedBox(height: 8),
            Text(
              widget.product['name'] ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (widget.product['product_information'] != null)
              Text(
                widget.product['product_information'],
                style: const TextStyle(color: Colors.black87),
              ),
            const SizedBox(height: 12),
            Text(
              "Price${hasSizeOptions ? ' by Size' : ''}:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (hasSizeOptions)
              ...sizes.map((s) => Text("- ${s['size']}g: GHS ${s['price']}"))
            else
              Text("GHS ${sizes.first['price']}"),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart),
                label: const Text("Order Now"),
                onPressed: _showOrderDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
