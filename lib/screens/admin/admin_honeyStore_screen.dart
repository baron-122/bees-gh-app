import 'dart:io';
import 'dart:ui';
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

  // Customer Orders Filter
  final TextEditingController filterNameController = TextEditingController();
  final TextEditingController filterPhoneController = TextEditingController();
  String? filterStatus;

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

  void _showProductPreview(BuildContext context, String docId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white.withOpacity(0.1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(
                maxHeight: 500,
                minWidth: 300,
                maxWidth: 400,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? 'Product',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Category: ${data['category']}", style: const TextStyle(color: Colors.white)),
                          Text("Info: ${data['product_information']}", style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 12),
                          const Text(
                            'Product Sizes Available',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 25),
                          ),
                          const SizedBox(height: 4),

                          // Glassy cards for each size
                          ...List.from(data['sizes'] ?? []).map((s) {
                            final size = s['size'];
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.brown.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.brown.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    size != null ? "${s['size']}kg" : "${s['quantity']} units",
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                  Text("Qty: ${s['quantity'] ?? ''}", style: const TextStyle(color: Colors.white)),
                                  Text("Price: GHS ${s['price'] ?? ''}", style: const TextStyle(color: Colors.white)),
                                ],
                              ),
                            );
                          }),

                          const SizedBox(height: 12),
                          const Text(
                            'Product Images',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 25),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.from(data['image_urls'] ?? []).map((url) {
                              return Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.brown.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.brown.withOpacity(0.3)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(url, width: 100, height: 100, fit: BoxFit.cover),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B4513), // Saddle brown
                          foregroundColor: Colors.white, // White text on button
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
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
  }

  void _showOrderPreview(BuildContext context, String docId, Map<String, dynamic> data) {
    String? status = data['status'] ?? 'Pending';
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white.withOpacity(0.1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), // Glassy background
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.4)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Order Details",
                    style: TextStyle(
                      color: Colors.white, // Gold title
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personal Information:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 25),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Full name: ${data['name'] ?? '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text("Phone: ${data['phone'] ?? ''}", style: const TextStyle(color: Colors.white)),
                        Text("Shipping Address: ${data['shipping_address'] ?? ''}", style: const TextStyle(color: Colors.white)),
                        const SizedBox(height: 8),
                        const Text(
                          'Order:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 25),
                        ),
                        const SizedBox(height: 4),
                        const SizedBox(height: 4),
                        ...List.from(data['items'] ?? []).map((it) {
                          final item = it is Map ? Map<String, dynamic>.from(it) : <String, dynamic>{};
                          final pname = (item['product_name'] ?? item['name'] ?? 'Unnamed').toString();
                          final qty = item['quantity']?.toString() ?? '0';
                          final unit = (item['unit_price'] ?? item['price'] ?? 0).toString();
                          final tot = item['total_price'] ??
                              (item['unit_price'] != null && item['quantity'] != null
                                  ? (item['unit_price'] * (item['quantity'] as num))
                                  : null);
                          final totStr = tot != null ? tot.toString() : 'N/A';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(pname, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                                Text("Quantity: $qty", style: const TextStyle(color: Colors.white)),
                                Text("Unit Price: GHS $unit", style: const TextStyle(color: Colors.white)),
                                Text("Total Price: GHS $totStr", style: const TextStyle(color: Colors.white)),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: status,
                          decoration: InputDecoration(
                            labelText: "Update Status",
                            labelStyle: const TextStyle(color: Colors.white),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.amber.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          dropdownColor: Colors.brown.shade400,
                          style: const TextStyle(color: Colors.white),
                          items: ['Pending', 'Processing', 'Shipped','Delivered']
                              .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s),
                          ))
                              .toList(),
                          onChanged: (val) => status = val,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B4513), // Saddle brown
                          foregroundColor: Colors.white, // White text on button
                        ),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('honeyStore_orders')
                              .doc(docId)
                              .update({'status': status});
                          Navigator.pop(context);
                        },
                        child: const Text("Update Status"),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Close", style: TextStyle(color: Colors.white)),
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
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Filter Orders"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: filterNameController,
              decoration: const InputDecoration(labelText: "Client Name"),
            ),
            TextField(
              controller: filterPhoneController,
              decoration: const InputDecoration(labelText: "Phone Number"),
            ),
            DropdownButtonFormField<String>(
              value: filterStatus,
              decoration: const InputDecoration(labelText: "Status"),
              items: ['Pending', 'Processing', 'Delivered']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => filterStatus = val,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () {
                filterNameController.clear();
                filterPhoneController.clear();
                filterStatus = null;
                Navigator.pop(context);
              },
              child: const Text("Clear")),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown.shade400),
              onPressed: () => Navigator.pop(context),
              child: const Text("Apply"))
        ],
      ),
    );
  }

  Query<Map<String, dynamic>> _ordersQuery() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('honeyStore_orders');
    if (filterNameController.text.isNotEmpty) {
      query = query.where('client_name', isEqualTo: filterNameController.text);
    }
    if (filterPhoneController.text.isNotEmpty) {
      query = query.where('phone', isEqualTo: filterPhoneController.text);
    }
    if (filterStatus != null && filterStatus!.isNotEmpty) {
      query = query.where('status', isEqualTo: filterStatus);
    }
    return query;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "HoneyStore Admin Page",
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
          )
        ),
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Add Product Card
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white.withOpacity(0.6),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(" Add Product to Store", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: Icon(isFormVisible ? Icons.close : Icons.add, color: Colors.brown.shade800),
                          onPressed: () => setState(() => isFormVisible = !isFormVisible),
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

            // Available Store Products Card
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white.withOpacity(0.6),
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
                              subtitle: Text("Total Qty: ${data['quantity'] ?? 0}"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_red_eye, color: Colors.brown),
                                    tooltip: "Preview Product",
                                    onPressed: () => _showProductPreview(context, doc.id, data),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Color(0xFF8B4513)),
                                    tooltip: "Delete Product",
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => Dialog(
                                          backgroundColor: Colors.white.withOpacity(0.1),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(20),
                                            child: BackdropFilter(
                                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                              child: Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                                                ),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Text(
                                                      "Confirm Delete",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 25,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    const Text(
                                                      "Are you sure you want to delete this product?",
                                                      style: TextStyle(color: Colors.white),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                      children: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context, false),
                                                          child: const Text(
                                                            "Cancel",
                                                            style: TextStyle(color: Color(0xFF8B4513)),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        ElevatedButton(
                                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B4513)),
                                                          onPressed: () => Navigator.pop(context, true),
                                                          child: const Text(
                                                            "Delete",
                                                            style: TextStyle(color: Colors.white),
                                                          ),
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
                                        await FirebaseFirestore.instance.collection('products_honeyStore').doc(doc.id).delete();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Customer Orders Card
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white.withOpacity(0.6),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Customer Orders", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.filter_list_sharp, color: Color(0xFF8B4513)),
                          onPressed: _showFilterDialog,
                        )
                      ],
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: _ordersQuery().snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const CircularProgressIndicator();
                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) return const Text("- No Orders Found -");
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final firstItem = (data['items'] ?? []).isNotEmpty ? data['items'][0] : null;
                            final imageUrl = firstItem != null ? firstItem['image_url'] ?? null : null;
                            final productName = firstItem != null ? firstItem['product_name'] ?? firstItem['name'] ?? 'Unnamed' : '';
                            final quantity = firstItem != null ? firstItem['quantity']?.toString() ?? '0' : '0';
                            final total = firstItem != null ? firstItem['total_price']?.toString() ?? '0' : '0';
                            final status = data['status'] ?? 'Pending';

                            return Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              color: Colors.white.withOpacity(0.6),
                              elevation: 1,
                              child: ListTile(
                                leading: imageUrl != null ? Image.network(imageUrl, width: 60, height: 90) : null,
                                title: Text(productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("$status"),

                                trailing: TextButton(
                                  child: const Icon(Icons.remove_red_eye, color: Color(0xFF8B4513)),
                                  onPressed: () => _showOrderPreview(context, doc.id, data),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
                  const Text("Enable Size Options", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  Switch(
                    activeColor: const Color(0xFF8B4513),
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
                const Text("Sizes (kg), Quantity & Price", style: TextStyle(color: Colors.black),),
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
                  icon: const Icon(Icons.add, color: Colors.black,),
                  label: const Text("Add Size Option", style: TextStyle(color: Colors.black),),
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
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _selectImages,
                icon: const Icon(Icons.image),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[800],
                  foregroundColor: const Color(0xFFFFD54F),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),

                label: const Text("Select Images (max 500KB each)",),
              ),
              const SizedBox(height: 2),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: images.map((f) => Image.file(f, width: 80, height: 80)).toList(),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: isUploading ? null : _uploadProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[800],
                  foregroundColor: const Color(0xFFFFD54F),
                  padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                   borderRadius: BorderRadius.circular(30),
                   ),
                 ),
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
}
