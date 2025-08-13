import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserAccountsScreen extends StatefulWidget {
  const UserAccountsScreen({Key? key}) : super(key: key);

  @override
  State<UserAccountsScreen> createState() => _UserAccountsScreenState();
}

class _UserAccountsScreenState extends State<UserAccountsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isOrdersExpanded = false;
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> allOrders = [];
  List<Map<String, dynamic>> filteredOrders = [];

  /// Default to Pending on open as requested
  String? selectedStatusFilter = 'Pending';

  final List<String> statusOptions = [
    'Pending',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserAndOrders();
  }

  Future<void> _loadUserAndOrders() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      // nothing to do when no user
      return;
    }

    // Fetch user doc
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final user = userDoc.data();
    if (user == null) {
      // still show an empty screen if no user doc
      setState(() {
        userData = {};
        allOrders = [];
        filteredOrders = [];
      });
      return;
    }

    final phone = (user['phone'] ?? '').toString();

    // We try both queries and merge uniquely because some clients may not have user_id saved
    final Map<String, Map<String, dynamic>> ordersMap = {};

    // Query by user_id
    final qByUserId = await _firestore
        .collection('honeyStore_orders')
        .where('user_id', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .get();
    for (var d in qByUserId.docs) {
      final data = Map<String, dynamic>.from(d.data() as Map);
      data['_docId'] = d.id;
      ordersMap[d.id] = data;
    }

    // Query by phone (fallback)
    if (phone.isNotEmpty) {
      final qByPhone = await _firestore
          .collection('honeyStore_orders')
          .where('phone', isEqualTo: phone)
          .orderBy('created_at', descending: true)
          .get();
      for (var d in qByPhone.docs) {
        final data = Map<String, dynamic>.from(d.data() as Map);
        data['_docId'] = d.id;
        ordersMap[d.id] = data;
      }
    }

    final ordersList = ordersMap.values.toList();

    setState(() {
      userData = Map<String, dynamic>.from(user);
      allOrders = ordersList;
      _applyFilter();
    });
  }

  void _applyFilter() {
    if (selectedStatusFilter == null) {
      filteredOrders = List<Map<String, dynamic>>.from(allOrders);
    } else {
      final sel = selectedStatusFilter!.toLowerCase();
      filteredOrders = allOrders.where((order) {
        final s = (order['status'] ?? 'Pending').toString().toLowerCase();
        return s == sel;
      }).toList();
    }
  }

  void _openStatusFilterDialog() {
    String? tempSelection = selectedStatusFilter;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Orders by Status'),
        content: DropdownButtonFormField<String>(
          value: tempSelection,
          isExpanded: true,
          hint: const Text('Select Status'),
          items: statusOptions
              .map((status) => DropdownMenuItem(value: status, child: Text(status)))
              .toList(),
          onChanged: (value) => tempSelection = value,
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Clear filter -> show all
              setState(() {
                selectedStatusFilter = null;
                _applyFilter();
              });
              Navigator.pop(context);
            },
            child: const Text("Clear"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                selectedStatusFilter = tempSelection;
                _applyFilter();
              });
              Navigator.pop(context);
            },
            child: const Text("Apply"),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.grey;
      case 'processing':
        return Colors.orangeAccent;
      case 'shipped':
        return Colors.blueAccent;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  void _showOrderPreview(Map<String, dynamic> order) {
    final items = (order['items'] ?? order['products'] ?? order['products_list'] ?? []) as List<dynamic>? ?? [];
    final createdAt = order['created_at'] is Timestamp ? (order['created_at'] as Timestamp).toDate() : null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Order Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (createdAt != null) Text('Placed: ${createdAt.toLocal()}'),
              const SizedBox(height: 8),
              Text('Full name: ${order['name'] ?? '${userData?['first_name'] ?? ''} ${userData?['last_name'] ?? ''}'}'),
              Text('Phone: ${order['phone'] ?? userData?['phone'] ?? ''}'),
              Text('Shipping address: ${order['shipping_address'] ?? ''}'),
              const SizedBox(height: 12),
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (items.isEmpty) const Text('- No items recorded -'),
              ...items.map((it) {
                final item = it is Map ? Map<String, dynamic>.from(it) : <String, dynamic>{};
                final pname = (item['product_name'] ?? item['name'] ?? 'Unnamed').toString();
                final qty = item['quantity']?.toString() ?? '0';
                final unit = (item['unit_price'] ?? item['price'] ?? item['unit'] ?? 0).toString();
                // total prefer explicit total_price field if present
                final tot = item['total_price'] ??
                    (item['unit_price'] != null && item['quantity'] != null
                        ? (item['unit_price'] * (item['quantity'] as num))
                        : null);
                final totStr = tot != null ? tot.toString() : 'N/A';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(pname, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('Qty: $qty   •   Unit: GHS $unit   •   Total: GHS $totStr'),
                  ]),
                );
              }),
              const SizedBox(height: 12),
              Text('Payment method: ${order['payment_method'] ?? order['paymentMethod'] ?? 'N/A'}'),
              Text('Status: ${order['status'] ?? 'Pending'}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    // items can be under different keys
    final items = (order['items'] ?? order['products'] ?? order['products_list'] ?? []) as List<dynamic>? ?? [];
    final firstItem = items.isNotEmpty && items.first is Map ? Map<String, dynamic>.from(items.first) : <String, dynamic>{};
    final imageUrl = (firstItem['image_url'] ??
        firstItem['product_image'] ??
        firstItem['image'] ??
        order['image_url'] ??
        order['product_image'])?.toString() ??
        '';
    final productName = (firstItem['product_name'] ?? firstItem['name'] ?? (items.isNotEmpty ? 'Item' : 'No items')).toString();
    final qty = (firstItem['quantity'] ?? '').toString();
    final status = (order['status'] ?? 'Pending').toString();

    // compute total price of entire order if possible
    double total = 0.0;
    for (var it in items) {
      if (it is Map) {
        final tot = it['total_price'];
        if (tot is num) {
          total += tot.toDouble();
        } else if (it['unit_price'] != null && it['quantity'] != null) {
          final u = (it['unit_price'] as num).toDouble();
          final q = (it['quantity'] as num).toDouble();
          total += u * q;
        }
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            // thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 64, height: 64, color: Colors.grey[200], child: const Icon(Icons.broken_image)))
                  : Container(width: 64, height: 64, color: Colors.grey[200], child: const Icon(Icons.image)),
            ),
            const SizedBox(width: 12),
            // main info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Qty: $qty'),
                  const SizedBox(height: 10),
                  // status chip at bottom-left
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
            // right side: total + preview
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('GHS ${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                IconButton(
                  icon: const Icon(Icons.remove_red_eye),
                  onPressed: () => _showOrderPreview(order),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Future<String> _getProductImage(String productName) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products_honeyStore')
        .where('name', isEqualTo: productName)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first['image_url'] ?? '';
    }
    return '';
  }

  void _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    // While userData is loading show loader
    if (userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final totalOrdersCount = allOrders.length;
    final shownCount = filteredOrders.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Account'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // ORDERS OUTER CARD
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header row with title, counts, filter & expand
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Text('Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                                    child: Text('$totalOrdersCount'),
                                  ),
                                  const SizedBox(width: 8),
                                  if (selectedStatusFilter != null)
                                    Chip(
                                      label: Text(selectedStatusFilter!),
                                      backgroundColor: _getStatusColor(selectedStatusFilter!),
                                      labelStyle: const TextStyle(color: Colors.white),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.filter_list),
                              tooltip: 'Filter orders',
                              onPressed: _openStatusFilterDialog,
                            ),
                            IconButton(
                              icon: Icon(isOrdersExpanded ? Icons.expand_less : Icons.expand_more),
                              onPressed: () {
                                setState(() {
                                  isOrdersExpanded = !isOrdersExpanded;
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // If collapsed show a brief summary
                        if (!isOrdersExpanded)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              selectedStatusFilter != null
                                  ? 'Showing $shownCount of $totalOrdersCount orders (filter: ${selectedStatusFilter!})'
                                  : 'Showing $shownCount orders',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ),

                        // Expanded: list each order as its own inner card
                        if (isOrdersExpanded)
                          Column(
                            children: filteredOrders.isEmpty
                                ? [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(selectedStatusFilter == null ? 'No orders yet.' : 'No orders match this filter.'),
                              )
                            ]
                                : filteredOrders.map((o) => _buildOrderCard(o)).toList(),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Personal Information full card (same width as orders)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Personal Information', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('First Name: ${userData?['first_name'] ?? 'N/A'}'),
                      Text('Last Name: ${userData?['last_name'] ?? 'N/A'}'),
                      Text('Region: ${userData?['region'] ?? 'N/A'}'),
                      Text('Town: ${userData?['town'] ?? 'N/A'}'),
                      Text('Community: ${userData?['community'] ?? 'N/A'}'),
                      Text('Email: ${userData?['email'] ?? 'N/A'}'),
                    ]),
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
