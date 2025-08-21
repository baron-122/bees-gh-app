/*
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';




class BeeChampionHome extends StatefulWidget {
  const BeeChampionHome({super.key});

  @override
  State<BeeChampionHome> createState() => _BeeChampionHomeState();
}

class _BeeChampionHomeState extends State<BeeChampionHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Admin Home Page",
          style: TextStyle(
            color: Color(0xFFFFD54F),
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
      child:
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("All Stocks Table", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('bee_transactions')
                            .where('bee_champion_id', isEqualTo: loggedInBeeChampion).snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Text("No stock data available.");
                          }

                          // 🔢 Sum quantities for each product
                          final Map<String, double> productTotals = {};
                          for (var doc in snapshot.data!.docs) {
                            final data = doc.data() as Map<String, dynamic>;
                            final String product = data['product'] ?? 'Unknown';
                            final double qty = (data['quantity'] ?? 0).toDouble();
                            productTotals[product] = (productTotals[product] ?? 0) + qty;
                          }

                          return DataTable(
                            columns: const [
                              DataColumn(label: Text("Product")),
                              DataColumn(label: Text("Quantity Available")),
                            ],
                            rows: productTotals.entries.map((entry) {
                              return DataRow(cells: [
                                DataCell(Text(entry.key)),
                                DataCell(Text(entry.value.toStringAsFixed(2))),
                              ]);
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Transactions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('bee_transactions')
                            .where('bee_champion_id', isEqualTo: loggedInBeeChampion)
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Text("No transactions found.");
                          }

                          final rows = snapshot.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            data['docId'] = doc.id;
                            return DataRow(cells: [
                              DataCell(Text(data['seller_name'] ?? '')),
                              DataCell(Text(data['quantity'].toString())),
                              DataCell(Text(data['payment_status'])),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.visibility),
                                  onPressed: () => _showTransactionDetails(data),
                                ),
                              ),
                            ]);
                          }).toList();

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text("Seller")),
                                DataColumn(label: Text("Qty(kg)")),
                                DataColumn(label: Text("Payment")),
                                DataColumn(label: Text(" ")), // Preview icon
                              ],
                              rows: rows,
                            ),
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
      ),
    );
  }


  final loggedInBeeChampion = FirebaseAuth.instance.currentUser?.uid;

  void _retryPayment(Map<String, dynamic> data){

  }

  void _showTransactionDetails(Map<String, dynamic> data) {
    final TextEditingController momoIdController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool showPaymentFields = false;


    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Transaction Details"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Seller: ${data['seller_name'] ?? ''}"),
                Text("Phone: ${data['phone_number'] ?? ''}"),
                Text("Product: ${data['product'] ?? ''}"),
                Text("Quantity: ${data['quantity']} kg"),
                Text("Unit Price: GHS ${data['unit_price']}"),
                Text("Total: GHS ${data['total_price']}"),
                Text("Payment Status: ${data['payment_status']}"),
                if (data['payment_status'] == 'Paid')
                  Text("Transaction ID: ${data['momo_transaction_id'] ?? 'N/A'}"),

                const SizedBox(height: 10),

                // Show MoMo & Date Fields if Pay is clicked
                if (showPaymentFields) ...[
                  TextFormField(
                    controller: momoIdController,
                    decoration: const InputDecoration(
                      labelText: "MoMo Transaction ID",
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: "Payment Date",
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        controller: TextEditingController(
                          text: "${selectedDate.toLocal()}".split(' ')[0],
                        ),
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
            if (data['payment_status'] != 'Paid' && !showPaymentFields)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    showPaymentFields = true;
                  });
                },
                child: const Text('Pay'),
              ),
            if (showPaymentFields)
              ElevatedButton(
                onPressed: () async {
                  final momoId = momoIdController.text.trim();
                  if (momoId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter MoMo Transaction ID")),
                    );
                    return;
                  }

                  try {
                    // Update Firestore
                    final transactionRef = FirebaseFirestore.instance
                        .collection('bee_transactions')
                        .doc(data['docId']);

                    await transactionRef.update({
                      'payment_status': 'Paid',
                      'momo_transaction_id': momoId,
                      'payment_date': Timestamp.fromDate(selectedDate),
                    });

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Payment marked as Paid")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to update: $e")),
                    );
                  }
                },
                child: const Text("Confirm Payment"),
              ),
          ],
        ),
      ),
    );
  }
}
*/
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BeeChampionHome extends StatefulWidget {
  const BeeChampionHome({super.key});

  @override
  State<BeeChampionHome> createState() => _BeeChampionHomeState();
}

class _BeeChampionHomeState extends State<BeeChampionHome> {
  final loggedInBeeChampion = FirebaseAuth.instance.currentUser?.uid;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Admin Home Page",
          style: TextStyle(
            color: Color(0xFFFFD54F),
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
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Glass card: All Stocks
                _buildGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("All Stocks Table",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('bee_transactions')
                            .where('bee_champion_id',
                            isEqualTo: loggedInBeeChampion)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Text("No stock data available.");
                          }

                          final Map<String, double> productTotals = {};
                          for (var doc in snapshot.data!.docs) {
                            final data =
                            doc.data() as Map<String, dynamic>;
                            final String product =
                                data['product'] ?? 'Unknown';
                            final double qty =
                            (data['quantity'] ?? 0).toDouble();
                            productTotals[product] =
                                (productTotals[product] ?? 0) + qty;
                          }

                          return DataTable(
                            columns: const [
                              DataColumn(label: Text("Product")),
                              DataColumn(label: Text("Quantity Available")),
                            ],
                            rows: productTotals.entries.map((entry) {
                              return DataRow(cells: [
                                DataCell(Text(entry.key)),
                                DataCell(
                                    Text(entry.value.toStringAsFixed(2))),
                              ]);
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Glass card: Transactions
                _buildGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Transactions",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('bee_transactions')
                            .where('bee_champion_id', isEqualTo: loggedInBeeChampion)
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Text("No transactions found.");
                          }

                          /*
                          return ListView.builder(

                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              final doc = snapshot.data!.docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              data['docId'] = doc.id;

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  title: Text(data['seller_name'] ?? ''),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Quantity: ${data['quantity']} kg"),
                                      Text("Payment: ${data['payment_status']}"),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.visibility),
                                    onPressed: () => _showTransactionDetails(data),
                                  ),
                                ),
                              );
                            },
                          );

                           */
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              final doc = snapshot.data!.docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              data['docId'] = doc.id;

                              return _buildGlassCardInternal(
                                child: ListTile(
                                  title: Text(
                                    data['seller_name'] ?? '',
                                    style: const TextStyle(color: Colors.black), // ensure visibility on glass
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Quantity: ${data['quantity']} kg",
                                          style: const TextStyle(color: Colors.black)),
                                      Text("Payment: ${data['payment_status']}",
                                          style: const TextStyle(color: Colors.black)),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.visibility, color: Colors.black),
                                    onPressed: () => _showTransactionDetails(data),
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
              ],
            ),
          ),
        ),
      ),
    );
  }


  void _showTransactionDetails(Map<String, dynamic> data) {
    final TextEditingController momoIdController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool showPaymentFields = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.white.withOpacity(0.3),
          child: _buildGlassCardPop(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transaction Details:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 25),
                  ),
                  const SizedBox(height: 10),
                  Text("Seller: ${data['seller_name'] ?? ''}", style: TextStyle(color: Colors.white),),
                  Text("Phone: ${data['phone_number'] ?? ''}", style: TextStyle(color: Colors.white)),
                  Text("Product: ${data['product'] ?? ''}", style: TextStyle(color: Colors.white)),
                  Text("Quantity: ${data['quantity']} kg", style: TextStyle(color: Colors.white)),
                  Text("Unit Price: GHS ${data['unit_price']}", style: TextStyle(color: Colors.white)),
                  Text("Total: GHS ${data['total_price']}", style: TextStyle(color: Colors.white)),
                  Text("Payment Status: ${data['payment_status']}", style: TextStyle(color: Colors.white)),
                  if (data['payment_status'] == 'Paid')
                    Text(
                        "Transaction ID: ${data['momo_transaction_id'] ?? 'N/A'}", style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 10),

                  if (showPaymentFields) ...[
                    TextFormField(
                      controller: momoIdController,
                      cursorColor: Colors.white,
                      decoration: const InputDecoration(
                        labelText: "MoMo Transaction ID",
                          labelStyle: const TextStyle(color: Colors.white),
                          fillColor: Colors.white
                      ),
                        style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          cursorColor: Colors.white,
                          decoration: const InputDecoration(
                            labelText: "Payment Date",
                            labelStyle: const TextStyle(color: Colors.white),
                            fillColor: Colors.white,
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                            style: TextStyle(color: Colors.white),
                          controller: TextEditingController(
                            text: "${selectedDate.toLocal()}".split(' ')[0],
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Close", style: TextStyle(color: Colors.white)),
                      ),
                      if (data['payment_status'] != 'Paid' &&
                          !showPaymentFields)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown,
                          ),
                          onPressed: () {
                            setState(() {
                              showPaymentFields = true;
                            });
                          },
                          child: const Text(
                            'Pay',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      if (showPaymentFields)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown,
                          ),
                          onPressed: () async {
                            final momoId = momoIdController.text.trim();
                            if (momoId.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Please enter MoMo Transaction ID", style: TextStyle(color: Colors.white))),
                              );
                              return;
                            }

                            try {
                              final transactionRef = FirebaseFirestore
                                  .instance
                                  .collection('bee_transactions')
                                  .doc(data['docId']);

                              await transactionRef.update({
                                'payment_status': 'Paid',
                                'momo_transaction_id': momoId,
                                'payment_date':
                                Timestamp.fromDate(selectedDate),
                              });

                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                    Text("Payment marked as Paid")),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                    Text("Failed to update: $e")),
                              );
                            }
                          },
                          child: const Text(
                            "Confirm Payment",
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
  }

  // 🔮 Reusable glass card builder
  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.brown.shade200.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.brown.withOpacity(0.6), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassCardInternal({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.brown.shade50.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassCardPop({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.brown.shade200.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

