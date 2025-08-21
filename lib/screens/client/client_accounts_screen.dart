import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const Color kSandalBrown = Color(0xFF8B4513);

class UserAccountsScreen extends StatefulWidget {
  const UserAccountsScreen({super.key});

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
    if (uid == null) return;

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final user = userDoc.data();
    if (user == null) {
      setState(() {
        userData = {};
        allOrders = [];
        filteredOrders = [];
      });
      return;
    }

    final phone = (user['phone'] ?? '').toString();

    final Map<String, Map<String, dynamic>> ordersMap = {};

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
      builder: (context) => _GlassDialog(
        title: 'Filter Orders by Status',
        content: DropdownButtonFormField<String>(
          value: tempSelection,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(borderSide: BorderSide.none),
            filled: true,
          ),
          hint: const Text('Select Status'),
          items: statusOptions
              .map((status) =>
              DropdownMenuItem(value: status, child: Text(status)))
              .toList(),
          onChanged: (value) => tempSelection = value,
        ),
        actions: [
          TextButton(
            onPressed: () {
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
    final items = (order['items'] ??
        order['products'] ??
        order['products_list'] ??
        []) as List<dynamic>? ??
        [];
    final createdAt = order['created_at'] is Timestamp
        ? (order['created_at'] as Timestamp).toDate()
        : null;

    showDialog(
      context: context,
      builder: (_) => _GlassDialog(
        title: 'Order Details',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (createdAt != null)
              Text(
                'Order Placed: ${createdAt.toLocal()}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                    fontSize: 15
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'Personal Information:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 25),
            ),
            const SizedBox(height: 4),
            Text(
              'Full name: ${order['name'] ?? '${userData?['first_name'] ?? ''} ${userData?['last_name'] ?? ''}'}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Phone: ${order['phone'] ?? userData?['phone'] ?? ''}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Shipping address: ${order['shipping_address'] ?? ''}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              'Items:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 25),
            ),
            const SizedBox(height: 4),
            if (items.isEmpty)
              const Text('- No items recorded -', style: TextStyle(color: Colors.white)),
            ...items.map((it) {
              final item = it is Map ? Map<String, dynamic>.from(it) : <String, dynamic>{};
              final pname = (item['product_name'] ?? item['name'] ?? 'Unnamed').toString();
              final qty = item['quantity']?.toString() ?? '0';
              final unit = (item['unit_price'] ?? item['price'] ?? item['unit'] ?? 0).toString();
              final tot = item['total_price'] ??
                  (item['unit_price'] != null && item['quantity'] != null
                      ? (item['unit_price'] * (item['quantity'] as num))
                      : null);
              final totStr = tot != null ? tot.toString() : 'N/A';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pname,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    const SizedBox(height: 4,),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                       Text('Quantity: $qty', style: TextStyle(color: Colors.white),),
                        Text('Unit Price: GHS $unit', style: TextStyle(color: Colors.white),),
                        Text('Total Price: GHS $totStr', style: TextStyle(color: Colors.white),),
                      ],
                    )
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            const Text(
              'Payment and Delivery:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 25),
            ),
            const SizedBox(height: 4),
            Text(
              'Payment method: ${order['payment_method'] ?? order['paymentMethod'] ?? 'N/A'}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Status: ${order['status'] ?? 'Pending'}',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
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
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final items = (order['items'] ??
        order['products'] ??
        order['products_list'] ??
        []) as List<dynamic>? ??
        [];
    final firstItem = items.isNotEmpty && items.first is Map
        ? Map<String, dynamic>.from(items.first)
        : <String, dynamic>{};
    final imageUrl = (firstItem['image_url'] ??
        firstItem['product_image'] ??
        firstItem['image'] ??
        order['image_url'] ??
        order['product_image'])
        ?.toString() ??
        '';
    final productName = (firstItem['product_name'] ??
        firstItem['name'] ??
        (items.isNotEmpty ? 'Item' : 'No items'))
        .toString();
    final qty = (firstItem['quantity'] ?? '').toString();
    final status = (order['status'] ?? 'Pending').toString();

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

    return _GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 64,
                height: 64,
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image),
              ),
            )
                : Container(
              width: 64,
              height: 64,
              color: Colors.grey[200],
              child: const Icon(Icons.image),
            ),
          ),
          const SizedBox(width: 12),
          // main info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    )),
                const SizedBox(height: 4),
                const SizedBox(height: 10),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusColor(status).withOpacity(0.35),
                        blurRadius: 12,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          // right side: total + preview
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('GHS ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 8),
              _PrimaryIconButton(
                icon: Icons.remove_red_eye,
                tooltip: 'Preview',
                onPressed: () => _showOrderPreview(order),
                color: Colors.white,
              ),
            ],
          ),
        ],
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
    if (userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final totalOrdersCount = allOrders.length;
    final shownCount = filteredOrders.length;

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor:
        Colors.amber.shade100,
        iconTheme: const IconThemeData(color: kSandalBrown),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.brown[800],
          elevation: 6,
          shadowColor: Colors.black.withOpacity(0.25),
          centerTitle: true,
          iconTheme: const IconThemeData(color: kSandalBrown),
          titleTextStyle: const TextStyle(
            color: Color(0xFFFFD54F),
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: 0.3,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.brown[800],
            foregroundColor: const Color(0xFFFFD54F),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('User Account'),
          automaticallyImplyLeading: false,
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 8.0),
            ),
          ],
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
            ),
          ),
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadUserAndOrders,
              color: Colors.brown.shade800,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _GlassCard(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          child: Row(
                            children: [
                              _AvatarBadge(name: userData?['first_name'] ?? ''),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${userData?['first_name'] ?? ''} ${userData?['last_name'] ?? ''}'
                                          .trim()
                                          .isEmpty
                                          ? 'Client'
                                          : '${userData?['first_name'] ?? ''} ${userData?['last_name'] ?? ''}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: const [
                                        Icon(Icons.phone_iphone,
                                            size: 16, color: kSandalBrown),
                                        SizedBox(width: 6),
                                      ],
                                    ),
                                    Text(
                                      userData?['phone'] ?? '—',
                                      style:
                                      TextStyle(color: Colors.grey.shade800),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.shopping_bag_outlined,
                                      size: 20),
                                  const SizedBox(width: 8),
                                  const Text('Orders',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.55),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                    ),
                                    child: Text(
                                      '$totalOrdersCount',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (selectedStatusFilter != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                            selectedStatusFilter!)
                                            .withOpacity(1),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _getStatusColor(
                                                selectedStatusFilter!)
                                                .withOpacity(0.35),
                                            blurRadius: 12,
                                            spreadRadius: 0.5,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        selectedStatusFilter!,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  _PrimaryIconButton(
                                    color: Colors.white,
                                    icon: isOrdersExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    tooltip: isOrdersExpanded
                                        ? 'Collapse'
                                        : 'Expand',
                                    onPressed: () {
                                      setState(() {
                                        isOrdersExpanded = !isOrdersExpanded;
                                      });
                                    },
                                  ),
                                  _PrimaryIconButton(
                                    color: Colors.white,
                                    icon: Icons.filter_list,
                                    tooltip: 'Filter orders',
                                    onPressed: _openStatusFilterDialog,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              AnimatedCrossFade(
                                crossFadeState: isOrdersExpanded
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                                duration: const Duration(milliseconds: 250),
                                firstChild: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8),
                                  child: Text(
                                    selectedStatusFilter != null
                                        ? 'Showing $shownCount of $totalOrdersCount orders (filter: ${selectedStatusFilter!})'
                                        : 'Showing $shownCount orders',
                                    style:
                                    const TextStyle(color: Colors.black54),
                                  ),
                                ),
                                secondChild: Column(
                                  children: filteredOrders.isEmpty
                                      ? [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(selectedStatusFilter ==
                                          null
                                          ? 'No orders yet.'
                                          : 'No orders match this filter.'),
                                    )
                                  ]
                                      : filteredOrders
                                      .map((o) => Padding(
                                    padding:
                                    const EdgeInsets.symmetric(
                                        vertical: 6),
                                    child: _buildOrderCard(o),
                                  ))
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Personal Information (glassy)
                        _GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.person_outline, size: 20),
                                  SizedBox(width: 8),
                                  Text('Personal Information',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _InfoRow(
                                  icon: Icons.badge_outlined,
                                  label: 'First Name',
                                  value: userData?['first_name'] ?? 'N/A'),
                              _InfoRow(
                                  icon: Icons.badge,
                                  label: 'Last Name',
                                  value: userData?['last_name'] ?? 'N/A'),
                              _InfoRow(
                                  icon: Icons.map_outlined,
                                  label: 'Region',
                                  value: userData?['region'] ?? 'N/A'),
                              _InfoRow(
                                  icon: Icons.location_city_outlined,
                                  label: 'Town',
                                  value: userData?['town'] ?? 'N/A'),
                              _InfoRow(
                                  icon: Icons.home_work_outlined,
                                  label: 'Community',
                                  value: userData?['community'] ?? 'N/A'),
                              _InfoRow(
                                  icon: Icons.email_outlined,
                                  label: 'Email',
                                  value: userData?['email'] ?? 'N/A'),


                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _logout,
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* -------------------------- PREMIUM UI HELPERS -------------------------- */

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = 20,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.brown.shade200.withOpacity(0.45),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;
  const _GlassDialog({
    required this.title,
    required this.content,
    required this.actions,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune, color: kSandalBrown),
                    const SizedBox(width: 8),
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                content,
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions
                      .map((w) => Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: w,
                  ))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kSandalBrown),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                )),
          ),
          const SizedBox(width: 10),
          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryIconButton extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback onPressed;
  final Color? color; // background color for the button (now used)
  const _PrimaryIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    Key? key,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final btn = InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: color ?? Colors.brown[800],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.brown.shade200.withOpacity(0.45),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: kSandalBrown, size: 20),
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn;
  }
}

class _AvatarBadge extends StatelessWidget {
  final String name;
  const _AvatarBadge({required this.name, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final initials = name.isEmpty
        ? 'C'
        : name
        .trim()
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.brown[800],
          child: Text(
            initials,
            style: const TextStyle(
              color: Color(0xFFFFD54F),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD54F),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.brown.shade800, width: 1),
            ),
            child: Text(
              'Client',
              style: TextStyle(
                color: Colors.brown.shade900,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
