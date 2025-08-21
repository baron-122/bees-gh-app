import 'dart:ui';
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

  // --- Glassmorphic container builder
  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.brown.shade400.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
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
                          backgroundColor: Colors.brown,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(12),
                        ),
                        onPressed: () {
                          setDialogState(() {
                            currentIndex = (currentIndex + 1) % imageUrls.length;
                          });
                        },
                        child: const Icon(Icons.arrow_forward_ios, color: Colors.white),
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
/*
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
              backgroundColor: Colors.white.withOpacity(0.4),
              //insetPadding: const EdgeInsets.all(16),
              content: _glassCard(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Order Product",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD54F), // gold
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (hasSizeOptions)
                        DropdownButtonFormField<int>(
                          decoration: InputDecoration(labelText: "Please select a Size",
                          labelStyle: TextStyle(color: Color(0xFFFFD54F),)
                          ),
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
                        //style: TextStyle(color: Color(0xFFFFD54F),),
                        controller: unitPriceController,
                        decoration: InputDecoration(
                          labelText: "Unit Price",
                          labelStyle: TextStyle(color: Color(0xFFFFD54F),),
                          prefixText: "GHS ",
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: quantityController,
                        decoration: const InputDecoration(
                          labelText: "Quantity",
                          labelStyle: TextStyle(color: Color(0xFFFFD54F),),
                          hintText: "Enter quantity",
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
                          labelStyle: TextStyle(color: Color(0xFFFFD54F),),
                          prefixText: "GHS ",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
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
                  child: const Text("Add to Cart", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

 */
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
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            updateCosts(setState);

            return Dialog(
              backgroundColor: Colors.transparent, // remove double card effect
              insetPadding: const EdgeInsets.all(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.brown.shade200.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Order Product",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFD54F),
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (hasSizeOptions)
                          DropdownButtonFormField<int>(
                            dropdownColor: Colors.brown[700],
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: "Please select a Size",
                              labelStyle: TextStyle(color: Color(0xFFFFD54F)),
                            ),
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

                        const SizedBox(height: 12),
                        TextFormField(
                          readOnly: true,
                          controller: unitPriceController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: "Unit Price",
                            labelStyle: TextStyle(color: Color(0xFFFFD54F)),
                            prefixText: "GHS ",
                            prefixStyle: TextStyle(color: Colors.white),
                          ),
                        ),

                        const SizedBox(height: 12),
                        TextFormField(
                          controller: quantityController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: "Quantity",
                            labelStyle: TextStyle(color: Color(0xFFFFD54F)),
                            hintText: "Enter quantity",
                            hintStyle: TextStyle(color: Colors.white),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => updateCosts(setState),
                        ),

                        const SizedBox(height: 12),
                        TextFormField(
                          readOnly: true,
                          controller: totalCostController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: "Total Cost",
                            labelStyle: TextStyle(color: Color(0xFFFFD54F)),
                            prefixText: "GHS ",
                            prefixStyle: TextStyle(color: Colors.white),
                          ),
                        ),

                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel",
                                  style: TextStyle(color: Colors.white)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.brown,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
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
                              child: const Text("Add to Cart", style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
        title: Text(
          widget.product['name'] ?? 'Product',
          style: const TextStyle(
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
            colors: [Colors.amber.shade50, Colors.amber.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
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
                        onTap: () => setState(() => selectedImageIndex = index),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selectedImageIndex == index ? Colors.amber : Colors.grey,
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

              // --- Glass Card for Product Information ---
              _glassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.product['category'] != null)
                      Chip(
                        label: Text(
                          widget.product['category'],
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.brown[800],
                      ),
                    const SizedBox(height: 8),
                    Text(
                      widget.product['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD54F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.product['product_information'] != null)
                      Text(
                        widget.product['product_information'],
                        style: const TextStyle(color: Colors.white),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      "Price${hasSizeOptions ? ' by Size' : ''}:",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD54F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (hasSizeOptions)
                      ...sizes.map((s) => Text(
                        "- ${s['size']}g: GHS ${s['price']}",
                        style: const TextStyle(color: Colors.white),
                      ))
                    else
                      Text(
                        "GHS ${sizes.first['price']}",
                        style: const TextStyle(color: Colors.white),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(Icons.shopping_cart, color: Colors.white),
                  label: const Text("Order Now", style: TextStyle(color: Colors.white)),
                  onPressed: _showOrderDialog,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
