import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BeeChampionProductsPage extends StatefulWidget {
  const BeeChampionProductsPage({super.key});

  @override
  State<BeeChampionProductsPage> createState() => _BeeChampionProductsPageState();
}

class _BeeChampionProductsPageState extends State<BeeChampionProductsPage> {
  String mode = 'Random';
  final TextEditingController phoneOrIdController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitPriceController = TextEditingController();
  final TextEditingController momoTransactionController = TextEditingController();
  String selectedProduct = '';
  String paymentStatus = 'Pending';
  DateTime? dateOfSale;
  DateTime saleDate = DateTime.now();
  late final String? loggedInBeeChampion;

  List<Map<String, dynamic>> productList = [];

  @override
  void initState() {
    super.initState();
    quantityController.addListener(() {
      setState(() {});
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      loggedInBeeChampion = user.uid;
    }

    // 🟡 Fetch products from Firestore
    FirebaseFirestore.instance.collection('products').snapshots().listen((snapshot) {
      setState(() {
        productList = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'name': data['name'],
            'unit_price': data['unit_price'],
          };
        }).toList();
      });
    });
  }

  void _searchSellerOrTrainee() async {
    final value = phoneOrIdController.text.trim();
    if (value.isEmpty) return;

    if (mode == 'Random') {
      final sellerSnapshot = await FirebaseFirestore.instance
          .collection('sellers')
          .where('phone', isEqualTo: value)
          .get();

      if (sellerSnapshot.docs.isNotEmpty) {
        final data = sellerSnapshot.docs.first.data();
        nameController.text = data['name'] ?? '';
      } else {
        nameController.text = '';
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Seller not found. Enter name manually."),
        ));
      }
    } else {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('user_id_token', isEqualTo: value)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        final data = userSnapshot.docs.first.data();
        nameController.text = "${data['first_name']} ${data['last_name']}";
        phoneOrIdController.text = data['phone'] ?? '';
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Trainee not found with given ID."),
        ));
      }
    }
  }

  void _clearForm() {
    phoneOrIdController.clear();
    nameController.clear();
    quantityController.clear();
    unitPriceController.clear();
    momoTransactionController.clear();
    selectedProduct = '';
    paymentStatus = 'Pending';
    dateOfSale = null;
    setState(() {});
  }


  void _showSnackBar(String message){
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message),
      )
    );
  }

  Future<void> _saveTransaction() async {
    final sellerName = nameController.text.trim();
    final phoneNumber = phoneOrIdController.text.trim();
    final product = selectedProduct;
    final unitPrice = double.tryParse(unitPriceController.text.trim()) ?? 0;
    final quantity = double.tryParse(quantityController.text.trim()) ?? 0;
    final momoTxnId = momoTransactionController.text.trim();
    final selectedDate = saleDate;
    final sellerType = mode;


    if (sellerName.isEmpty || phoneNumber.isEmpty || product.isEmpty || quantity <= 0) {
      _showSnackBar("Please fill all required fields.");
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance.collection('bee_transactions').doc();

      final transactionData = {
        'seller_name': sellerName,
        'phone_number': phoneNumber,
        'product': product,
        'unit_price': unitPrice,
        'quantity': quantity,
        'total_price': quantity * unitPrice,
        'payment_status': paymentStatus,
        'momo_transaction_id': momoTxnId.isEmpty ? null : momoTxnId,
        'date_of_sale': selectedDate,
        'seller_type': sellerType,
        'trainer_id': sellerType == 'Trainee' ? phoneNumber : null,
        'seller_id': sellerType == 'Trainee' ? phoneNumber : null,
        'bee_champion_id': loggedInBeeChampion,
        'timestamp': FieldValue.serverTimestamp(),
      };


      if (sellerType == 'Random') {
        final sellerSnap = await FirebaseFirestore.instance
            .collection('sellers')
            .where('phone_number', isEqualTo: phoneNumber)
            .get();

        if (sellerSnap.docs.isEmpty) {
          await FirebaseFirestore.instance.collection('sellers').add({
            'name': sellerName,
            'phone_number': phoneNumber,
            'created_at': FieldValue.serverTimestamp(),
          });
        }
      }

      await docRef.set(transactionData);
      _showSnackBar("✅ Transaction recorded successfully.");
      _clearForm();
    } catch (e) {
      _showSnackBar("🚫 Failed to save transaction: $e");
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Purchase'), automaticallyImplyLeading: false,),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Center(
                      child: ToggleButtons(
                        isSelected: [mode == 'Random', mode == 'Trainee'],
                        onPressed: (index) {
                          setState(() => mode = index == 0 ? 'Random' : 'Trainee');
                        },
                        children: const [Text("Random"), Text("Trainee")],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: phoneOrIdController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: mode == 'Random' ? 'Phone Number' : 'Trainee ID',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _searchSellerOrTrainee,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name of Seller'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedProduct.isNotEmpty ? selectedProduct : null,
                      items: productList.map((product) {
                        return DropdownMenuItem<String>(
                          value: product['name'],
                          child: Text(product['name']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedProduct = val!;
                          final matchedProduct = productList.firstWhere((p) => p['name'] == val, orElse: () => {});
                          unitPriceController.text = matchedProduct['unit_price'].toString();
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Product'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantity (kg)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: unitPriceController,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Unit Price (GHS)'),
                    ),
                    const SizedBox(height: 12),
                    Text('Total Price: GHS ${_calculateTotal()}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: paymentStatus,
                      onChanged: (val) {
                        setState(() => paymentStatus = val!);
                      },
                      items: const [
                        DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                        DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                      ],
                      decoration: const InputDecoration(labelText: 'Payment Status'),
                    ),
                    if (paymentStatus == 'Paid')
                      TextField(
                        controller: momoTransactionController,
                        decoration: const InputDecoration(labelText: 'Momo Transaction ID'),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text("Date: ${DateFormat('yyyy-MM-dd').format(saleDate)}"),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: saleDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => saleDate = picked);
                            }
                          },
                          child: const Text("Pick Date"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: _clearForm,
                          child: const Text('Clear'),
                        ),
                        ElevatedButton(
                          onPressed: _saveTransaction,
                          child: const Text('Save'),
                        ),
                      ],
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

  double _calculateTotal() {
    final qty = double.tryParse(quantityController.text.trim()) ?? 0;
    final price = double.tryParse(unitPriceController.text.trim()) ?? 0;
    return qty * price;
  }
}
