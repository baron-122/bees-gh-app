import 'package:bees_gh_app/screens/client/client_landing_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'client_home_screen.dart';

const Color brownThemeColor = Color(0xFF8B4513);
class OrderConfirmationScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedProducts;
  final Map<String, dynamic> userDetails;


  const OrderConfirmationScreen({
    super.key,
    required this.selectedProducts,
    required this.userDetails,
  });

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController addressController;

  String shippingMethod = 'Delivery';
  String paymentMethod = 'Cash on Delivery';

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  Future<void> _initializeControllers() async {
    final userData = widget.userDetails;
    final userId = userData['user_id'];

    if ((userData['first_name'] ?? '').isEmpty && userId != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          widget.userDetails.addAll(data);
        }
      }
    }

    firstNameController = TextEditingController(text: widget.userDetails['first_name'] ?? '');
    lastNameController = TextEditingController(text: widget.userDetails['last_name'] ?? '');
    phoneController = TextEditingController(text: widget.userDetails['phone'] ?? '');
    emailController = TextEditingController(text: widget.userDetails['email'] ?? '');
    addressController = TextEditingController(text: widget.userDetails['shipping_address'] ?? '');

    setState(() => isLoading = false);
  }

  void _editUserDetails() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Shipping Details"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: "First Name"),
              ),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: "Last Name"),
              ),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Phone")),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: "Shipping Address")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final fullName = "$firstName $lastName";
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final shippingAddress = addressController.text.trim();

    // Validation
    if (firstName.isEmpty || lastName.isEmpty || phone.isEmpty || shippingAddress.isEmpty || widget.selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields before placing the order.")),
      );
      return;
    }

    try {
      String orderId = FirebaseFirestore.instance.collection('honeyStore_orders').doc().id;

      await FirebaseFirestore.instance.collection('honeyStore_orders').doc(orderId).set({
        'order_id': orderId,
        'user_id': FirebaseAuth.instance.currentUser?.uid ?? '',
        'first_name': firstName,
        'last_name': lastName,
        'name': fullName,
        'phone': phone,
        'email': email,
        'shipping_address': shippingAddress,
        'shipping_method': shippingMethod,
        'payment_method': paymentMethod,
        'status': 'Pending',
        'created_at': FieldValue.serverTimestamp(),
        'items': widget.selectedProducts.map((item) => {
          'product_id': item['product_id'],
          'product_name': item['product_name'],
          'quantity': item['quantity'],
          'unit_price': item['unit_price'],
          'total_price': item['total_price'],
          'image_url': item['image_url']
        }).toList(),
      });

      // Clear cart items belonging to this user (optional)
      final cartQuery = await FirebaseFirestore.instance
          .collection('shopping_cart')
          .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .get();
      for (var doc in cartQuery.docs) {
        await doc.reference.delete();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order placed successfully!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ClientLandingPage(firstName: firstName),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error placing order: $e")),
      );
    }
  }
/*
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final fullName = "${firstNameController.text} ${lastNameController.text}";

    return Scaffold(
      appBar: AppBar(title: const Text("Order Confirmation")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// Shipping Address Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Shipping Address", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text("Name: $fullName"),
                          Text("Phone: ${phoneController.text}"),
                          Text("Email: ${emailController.text}"),
                          Text("Shipping Address: ${addressController.text}"),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.edit, size: 30), onPressed: _editUserDetails),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Selected Products
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ListTile(title: Text("Selected Products", style: TextStyle(fontWeight: FontWeight.bold))),
                  ...widget.selectedProducts.map((p) => ListTile(
                    leading: Image.network(
                      p['image_url'] ?? '',
                      width: 50,
                      height: 50,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                    ),
                    title: Text(p['product_name'] ?? p['name'] ?? 'Unknown'),
                    subtitle: Text("Qty: ${p['quantity']}  •  GHS ${(p['subtotal'] ?? 0).toStringAsFixed(2)}"),
                  )),
                ],
              ),
            ),

            const SizedBox(height: 10),

            /// Shipping Method
            Card(
              child: Column(
                children: [
                  const ListTile(title: Text("Shipping Method", style: TextStyle(fontWeight: FontWeight.bold))),
                  RadioListTile(
                    title: const Text("Delivery"),
                    value: 'Delivery',
                    groupValue: shippingMethod,
                    onChanged: (val) => setState(() => shippingMethod = val!),
                  ),
                  RadioListTile(
                    title: const Text("Pick Up"),
                    value: 'Pick Up',
                    groupValue: shippingMethod,
                    onChanged: (val) => setState(() => shippingMethod = val!),
                  ),
                ],
              ),
            ),

            /// Payment Method
            Card(
              child: Column(
                children: [
                  const ListTile(title: Text("Payment Method", style: TextStyle(fontWeight: FontWeight.bold))),
                  RadioListTile(
                    title: const Text("Cash on Delivery"),
                    value: 'Cash on Delivery',
                    groupValue: paymentMethod,
                    onChanged: (val) => setState(() => paymentMethod = val!),
                  ),
                  RadioListTile(
                    title: const Text("Mobile Money"),
                    value: 'Mobile Money',
                    groupValue: paymentMethod,
                    onChanged: (val) => setState(() => paymentMethod = val!),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// Place Order Button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _placeOrder,
                child: const Text("Place Order"),
              ),
            ),
          ],
        ),
      ),
    );
  }

 */
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final fullName = "${firstNameController.text} ${lastNameController.text}";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
        title: const Text("Order Confirmation"),
      ),
      body: Stack(
        children: [
          // Gradient background
          Container(
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
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Shipping Address Card
                Card(
                  color: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Shipping Address",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 8),
                              Text("Name: $fullName"),
                              Text("Phone: ${phoneController.text}"),
                              Text("Email: ${emailController.text}"),
                              Text("Shipping Address: ${addressController.text}"),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 30),
                          onPressed: _editUserDetails,
                          color: Colors.brown[700],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Selected Products
                Card(
                  color: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ListTile(
                        title: Text("Selected Products",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ...widget.selectedProducts.map((p) => ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            p['image_url'] ?? '',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image),
                          ),
                        ),
                        title: Text(p['product_name'] ??
                            p['name'] ??
                            'Unknown'),
                        subtitle: Text(
                            "Qty: ${p['quantity']} • GHS ${(p['subtotal'] ?? 0).toStringAsFixed(2)}"),
                      )),
                    ],
                  ),
                ),

                const SizedBox(height: 10),


                // Shipping Method
                Card(

                  color: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      const ListTile(
                        title: Text("Shipping Method",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      RadioListTile<String>(
                        title: const Text(
                          "Delivery",
                          style: TextStyle(fontSize: 16, color: brownThemeColor),
                        ),
                        value: 'Delivery',
                        groupValue: shippingMethod,
                        activeColor: brownThemeColor,
                        onChanged: (val) => setState(() => shippingMethod = val!),
                      ),
                      RadioListTile<String>(
                        title: const Text(
                          "Pick Up",
                          style: TextStyle(fontSize: 16, color: brownThemeColor),
                        ),
                        value: 'Pick Up',
                        groupValue: shippingMethod,
                        activeColor: brownThemeColor,
                        onChanged: (val) => setState(() => shippingMethod = val!),
                      ),
                    ],
                  ),
                ),

                // Payment Method

                Card(
                  color: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      const ListTile(
                        title: Text("Payment Method",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      RadioListTile<String>(
                        title: const Text(
                          'Cash on Delivery',
                          style: TextStyle(fontSize: 16, color: brownThemeColor),
                        ),
                        value: 'COD',
                        groupValue: paymentMethod,
                        activeColor: brownThemeColor, // brown theme color
                        onChanged: (value) {
                          setState(() {
                            paymentMethod = value!;
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text(
                          'Mobile Money',
                          style: TextStyle(fontSize: 16, color: brownThemeColor),
                        ),
                        value: 'MOMO',
                        groupValue: paymentMethod,
                        activeColor: brownThemeColor, // brown theme color
                        onChanged: (value) {
                          setState(() {
                            paymentMethod = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Place Order Button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown[800],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _placeOrder,
                    child: const Text(
                      "Place Order",
                      style: TextStyle(fontSize: 16, color: Colors.white),
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

}
