import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class AdminHoneyStoreScreen extends StatefulWidget {
  const AdminHoneyStoreScreen({super.key});

  @override
  State<AdminHoneyStoreScreen> createState() => _AdminHoneyStoreScreenState();
}

class _AdminHoneyStoreScreenState extends State<AdminHoneyStoreScreen> {
  bool isFormVisible = true;
  final _formKey = GlobalKey<FormState>();
  String? selectedCategory;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController infoController = TextEditingController();
  List<Map<String, dynamic>> sizes = [];
  final List<File> images = [];
  bool isUploading = false;
  bool enableSizes = true;
  int? quantity;
  int? unitPrice;

  Future<List<String>> _fetchCategories() async {
    final snapshot = await FirebaseFirestore.instance.collection('product_categories').get();
    return snapshot.docs.map((doc) => doc['name'].toString()).toList();
  }

  Future<void> _selectImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty) return;

    for (final image in picked) {
      final file = File(image.path);
      final size = await file.length();
      if (size > 500 * 1024) {
        final dir = await getTemporaryDirectory();
        final targetPath = '${dir.path}/${const Uuid().v4()}.jpg';
        final compressed = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          quality: 75,
        );
        if (compressed != null) images.add(compressed as File);
      } else {
        images.add(file);
      }
    }
    setState(() {});
  }

  Future<List<String>> _uploadImages() async {
    final urls = <String>[];
    for (final image in images) {
      final ref = FirebaseStorage.instance.ref('honey_store_images/${const Uuid().v4()}.jpg');
      await ref.putFile(image);
      final url = await ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  void _addSize() {
    sizes.add({'size': null, 'quantity': null, 'price': null});
    setState(() {});
  }

  void _uploadProduct() async {
    if (!_formKey.currentState!.validate() || images.isEmpty) return;
    if (enableSizes && sizes.isEmpty) return;
    if (!enableSizes && (quantity == null || unitPrice == null)) return;

    setState(() => isUploading = true);
    final imageUrls = await _uploadImages();

    final productData = {
      'category': selectedCategory,
      'name': nameController.text.trim(),
      'product_information': infoController.text.trim(),
      'sizes': enableSizes ? sizes : [{'size': null, 'quantity': quantity, 'price': unitPrice}],
      'quantity': enableSizes
          ? sizes.fold<int>(0, (sum, s) => sum + (s['quantity'] as int? ?? 0))
          : (quantity ?? 0),
      'image_urls': imageUrls,
      'created_at': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('products_honeyStore').add(productData);
    setState(() {
      isUploading = false;
      nameController.clear();
      infoController.clear();
      sizes.clear();
      images.clear();
      quantity = null;
      unitPrice = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Honey Store Admin"), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Add Product to Store",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: Icon(isFormVisible ? Icons.close : Icons.add),
                          onPressed: () {
                            setState(() {
                              isFormVisible = !isFormVisible;
                            });
                          },
                        )
                      ],
                    ),
                    AnimatedCrossFade(
                      firstChild: _buildAddForm(),
                      secondChild: const SizedBox.shrink(),
                      crossFadeState: isFormVisible ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                      duration: const Duration(milliseconds: 300),
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Available Store Products", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    /*
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('products_honeyStore').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const CircularProgressIndicator();
                        return ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: snapshot.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return ListTile(
                              title: Text(data['name'] ?? 'Unnamed'),
                              //subtitle: Text("Total Qty: ${data['quantity']}"),
                              trailing: TextButton(
                                child: const Text(),
                                onPressed: () => _showProductPreview(context, doc.id, data),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    )

                     */
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('products_honeyStore').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const CircularProgressIndicator();
                        return ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: snapshot.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return ListTile(
                              title: Text(data['name'] ?? 'Unnamed'),
                              subtitle: Text("Total Qty: ${data['quantity'] ?? 0}"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                                    tooltip: "Preview Product",
                                    onPressed: () => _showProductPreview(context, doc.id, data),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: "Delete Product",
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text("Confirm Delete"),
                                          content: const Text("Are you sure you want to delete this product?"),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade200),
                                              onPressed: () => Navigator.pop(context, true),
                                              child: const Text("Delete"),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await FirebaseFirestore.instance
                                            .collection('products_honeyStore')
                                            .doc(doc.id)
                                            .delete();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    )

                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAddForm() {
    return Form(
      key: _formKey,
      child: FutureBuilder<List<String>>(
        future: _fetchCategories(),
        builder: (context, snapshot) {
          final categories = snapshot.data ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: "Category"),
                items: categories.map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                )).toList(),
                onChanged: (value) => setState(() => selectedCategory = value),
              ),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (val) => val!.isEmpty ? 'Enter product name' : null,
              ),
              TextFormField(
                controller: infoController,
                decoration: const InputDecoration(labelText: 'Product Information'),
                maxLines: 4,
                validator: (val) => val!.isEmpty ? 'Enter product info' : null,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Enable Size Options", style: TextStyle(fontWeight: FontWeight.bold)),
                  Switch(
                    value: enableSizes,
                    onChanged: (val) {
                      setState(() {
                        enableSizes = val;
                        sizes.clear();
                        quantity = null;
                        unitPrice = null;
                      });
                    },
                  )
                ],
              ),
              const SizedBox(height: 10),
              if (enableSizes) ...[
                const Text("Sizes (kg), Quantity & Price"),
                ...sizes.map((s) {
                  final i = sizes.indexOf(s);
                  return Row(
                    children: [
                      Expanded(child: TextFormField(
                        decoration: const InputDecoration(labelText: 'Size'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => sizes[i]['size'] = int.tryParse(v),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: TextFormField(
                        decoration: const InputDecoration(labelText: 'Qty'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => sizes[i]['quantity'] = int.tryParse(v),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: TextFormField(
                        decoration: const InputDecoration(labelText: 'Price (GHS)'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => sizes[i]['price'] = int.tryParse(v),
                      )),
                    ],
                  );
                }),
                TextButton.icon(
                  onPressed: _addSize,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Size Option"),
                ),
              ] else ...[
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => quantity = int.tryParse(v),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Unit Price (GHS)'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => unitPrice = int.tryParse(v),
                ),
              ],
              ElevatedButton.icon(
                onPressed: _selectImages,
                icon: const Icon(Icons.image),
                label: const Text("Select Images (max 500KB each)"),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: images.map((f) => Image.file(f, width: 80, height: 80)).toList(),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: isUploading ? null : _uploadProduct,
                child: isUploading
                    ? const CircularProgressIndicator()
                    : const Text("Upload Product"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showProductPreview(BuildContext context, String docId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(data['name'] ?? 'Product'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Category: ${data['category']}"),
              Text("Info: ${data['product_information']}"),
              const SizedBox(height: 10),
              Text("Sizes:"),
              ...List.from(data['sizes'] ?? []).map((s) {
                final size = s['size'];
                return Text(size != null
                    ? "- ${s['size']}kg: ${s['quantity']} units @ GHS ${s['price']}"
                    : "- ${s['quantity']} units @ GHS ${s['price']}");
              }),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.from(data['image_urls'] ?? [])
                    .map<Widget>((url) => Image.network(url, width: 80, height: 80))
                    .toList(),
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }
}


/*
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class AdminHoneyStoreScreen extends StatefulWidget {
  const AdminHoneyStoreScreen({super.key});

  @override
  State<AdminHoneyStoreScreen> createState() => _AdminHoneyStoreScreenState();
}

class _AdminHoneyStoreScreenState extends State<AdminHoneyStoreScreen> {
  bool isFormVisible = true;
  final _formKey = GlobalKey<FormState>();
  String? selectedCategory;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController infoController = TextEditingController();
  List<Map<String, dynamic>> sizes = [];
  final List<File> images = [];
  bool isUploading = false;
  bool enableSizes = true;
  int? quantity;
  int? unitPrice;

  Future<List<String>> _fetchCategories() async {
    final snapshot = await FirebaseFirestore.instance.collection('product_categories').get();
    return snapshot.docs.map((doc) => doc['name'].toString()).toList();
  }

  Future<void> _selectImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty) return;

    for (final image in picked) {
      final file = File(image.path);
      final size = await file.length();
      if (size > 500 * 1024) {
        final dir = await getTemporaryDirectory();
        final targetPath = '${dir.path}/${const Uuid().v4()}.jpg';
        final compressed = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          quality: 75,
        );
        if (compressed != null) images.add(compressed as File);
      } else {
        images.add(file);
      }
    }
    setState(() {});
  }

  Future<List<String>> _uploadImages() async {
    final urls = <String>[];
    for (final image in images) {
      final ref = FirebaseStorage.instance.ref('honey_store_images/${const Uuid().v4()}.jpg');
      await ref.putFile(image);
      final url = await ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  void _addSize() {
    sizes.add({'size': null, 'quantity': null, 'price': null});
    setState(() {});
  }

  void _uploadProduct() async {
    if (!_formKey.currentState!.validate() || images.isEmpty) return;
    if (enableSizes && sizes.isEmpty) return;
    if (!enableSizes && (quantity == null || unitPrice == null)) return;

    setState(() => isUploading = true);
    final imageUrls = await _uploadImages();

    final productData = {
      'category': selectedCategory,
      'name': nameController.text.trim(),
      'product_information': infoController.text.trim(),
      'sizes': enableSizes ? sizes : [{'size': null, 'quantity': quantity, 'price': unitPrice}],
      'quantity': enableSizes
          ? sizes.fold<int>(0, (sum, s) => sum + (s['quantity'] as int? ?? 0))
          : (quantity ?? 0),
      'image_urls': imageUrls,
      'created_at': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('products_honeyStore').add(productData);
    setState(() {
      isUploading = false;
      nameController.clear();
      infoController.clear();
      sizes.clear();
      images.clear();
      quantity = null;
      unitPrice = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Honey Store Admin"), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: FutureBuilder<List<String>>(
                    future: _fetchCategories(),
                    builder: (context, snapshot) {
                      final categories = snapshot.data ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Add Product to Store", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: selectedCategory,
                            decoration: const InputDecoration(labelText: "Category"),
                            items: categories.map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            )).toList(),
                            onChanged: (value) => setState(() => selectedCategory = value),
                          ),
                          TextFormField(
                            controller: nameController,
                            decoration: const InputDecoration(labelText: 'Product Name'),
                            validator: (val) => val!.isEmpty ? 'Enter product name' : null,
                          ),
                          TextFormField(
                            controller: infoController,
                            decoration: const InputDecoration(labelText: 'Product Information'),
                            maxLines: 4,
                            validator: (val) => val!.isEmpty ? 'Enter product info' : null,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Enable Size Options", style: TextStyle(fontWeight: FontWeight.bold)),
                              Switch(
                                value: enableSizes,
                                onChanged: (val) {
                                  setState(() {
                                    enableSizes = val;
                                    sizes.clear();
                                    quantity = null;
                                    unitPrice = null;
                                  });
                                },
                              )
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (enableSizes) ...[
                            const Text("Sizes (kg), Quantity & Price"),
                            ...sizes.map((s) {
                              final i = sizes.indexOf(s);
                              return Row(
                                children: [
                                  Expanded(child: TextFormField(
                                    decoration: const InputDecoration(labelText: 'Size'),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => sizes[i]['size'] = int.tryParse(v),
                                  )),
                                  const SizedBox(width: 8),
                                  Expanded(child: TextFormField(
                                    decoration: const InputDecoration(labelText: 'Qty'),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => sizes[i]['quantity'] = int.tryParse(v),
                                  )),
                                  const SizedBox(width: 8),
                                  Expanded(child: TextFormField(
                                    decoration: const InputDecoration(labelText: 'Price (GHS)'),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => sizes[i]['price'] = int.tryParse(v),
                                  )),
                                ],
                              );
                            }).toList(),
                            TextButton.icon(
                              onPressed: _addSize,
                              icon: const Icon(Icons.add),
                              label: const Text("Add Size Option"),
                            ),
                          ] else ...[
                            TextFormField(
                              decoration: const InputDecoration(labelText: 'Quantity'),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => quantity = int.tryParse(v),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              decoration: const InputDecoration(labelText: 'Unit Price (GHS)'),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => unitPrice = int.tryParse(v),
                            ),
                          ],
                          ElevatedButton.icon(
                            onPressed: _selectImages,
                            icon: const Icon(Icons.image),
                            label: const Text("Select Images (max 500KB each)"),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: images.map((f) => Image.file(f, width: 80, height: 80)).toList(),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: isUploading ? null : _uploadProduct,
                            child: isUploading
                                ? const CircularProgressIndicator()
                                : const Text("Upload Product"),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),


            const SizedBox(height: 24),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Available Store Products", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('products_honeyStore').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const CircularProgressIndicator();
                        return ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: snapshot.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return ListTile(
                              title: Text(data['name'] ?? 'Unnamed'),
                              subtitle: Text("Total Qty: ${data['quantity']}"),
                              trailing: TextButton(
                                child: const Text("Preview"),
                                onPressed: () => _showProductPreview(context, doc.id, data),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showProductPreview(BuildContext context, String docId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(data['name'] ?? 'Product'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Category: ${data['category']}"),
              Text("Info: ${data['product_information']}"),
              const SizedBox(height: 10),
              Text("Sizes:"),
              ...List.from(data['sizes'] ?? []).map((s) {
                final size = s['size'];
                return Text(size != null
                    ? "- ${s['size']}kg: ${s['quantity']} units @ GHS ${s['price']}"
                    : "- ${s['quantity']} units @ GHS ${s['price']}");
              }),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.from(data['image_urls'] ?? [])
                    .map<Widget>((url) => Image.network(url, width: 80, height: 80))
                    .toList(),
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }
}


*/
