/*
import 'package:bees_gh_app/screens/client/products_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ClientHomeScreen extends StatefulWidget {
  final String firstName;
  const ClientHomeScreen({super.key, required this.firstName});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  String selectedCategory = 'All';
  String searchQuery = '';

  final List<String> categories = ['All', 'Honey', 'Beeswax', 'Comb'];

  Stream<QuerySnapshot> getProducts() {
    return FirebaseFirestore.instance
        .collection('products_honeyStore')
        .snapshots();
  }

  String _getPrice(Map<String, dynamic> product) {
    final sizes = product['sizes'] as List<dynamic>?;
    if (sizes != null && sizes.isNotEmpty) {
      final first = sizes.first;
      if (first is Map && first['price'] != null) {
        return first['price'].toString();
      }
    }
    return '--';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TOP BAR
              Row(
                children: [
                  Image.asset('assets/images/bfd_landing.png', height: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Hi, ${widget.firstName}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// SEARCH BAR
              Material(
                borderRadius: BorderRadius.circular(30),
                color: Colors.grey[200],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "Search products...",
                      border: InputBorder.none,
                      suffixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.trim().toLowerCase();
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// CATEGORY FILTERS
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final selected = cat == selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            selectedCategory = cat;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              /// PRODUCT GRID
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: getProducts(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Convert Firestore docs to list
                    final allDocs = snapshot.data!.docs;

                    // Filter by category first
                    final categoryFiltered = selectedCategory == 'All'
                        ? allDocs
                        : allDocs.where((doc) {
                      final data =
                      doc.data() as Map<String, dynamic>;
                      final category =
                      (data['category'] ?? '').toString().toLowerCase();
                      return category ==
                          selectedCategory.toLowerCase();
                    }).toList();

                    // Then filter by search query (case-insensitive, within category)
                    final searchFiltered = searchQuery.isEmpty
                        ? categoryFiltered
                        : categoryFiltered.where((doc) {
                      final data =
                      doc.data() as Map<String, dynamic>;
                      final productName =
                      (data['name'] ?? '').toString().toLowerCase();
                      return productName.startsWith(searchQuery) ||
                          productName == searchQuery;
                    }).toList();

                    if (searchFiltered.isEmpty) {
                      return const Center(child: Text("No matching products."));
                    }

                    return GridView.builder(
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: searchFiltered.length,
                      itemBuilder: (context, index) {
                        final data = searchFiltered[index].data()
                        as Map<String, dynamic>;
                        final imageUrl =
                        (data['image_urls'] as List).isNotEmpty
                            ? data['image_urls'][0]
                            : '';
                        final productName = data['name'] ?? '';
                        final price = _getPrice(data);

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailsScreen(product: data),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                    imageUrl,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image,
                                        size: 48),
                                  )
                                      : Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image,
                                        size: 48),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text("GHS $price"),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

*/
import 'dart:ui';
import 'package:bees_gh_app/screens/client/products_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ClientHomeScreen extends StatefulWidget {
  final String firstName;
  const ClientHomeScreen({super.key, required this.firstName});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  String selectedCategory = 'All';
  String searchQuery = '';
  final List<String> categories = ['All', 'Honey', 'Beeswax', 'Comb'];

  Stream<QuerySnapshot> getProducts() {
    return FirebaseFirestore.instance
        .collection('products_honeyStore')
        .snapshots();
  }

  Color _cardBorder = Colors.grey.withOpacity(0.2);

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.80),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  String _getPrice(Map<String, dynamic> product) {
    final sizes = product['sizes'] as List<dynamic>?;
    if (sizes != null && sizes.isNotEmpty) {
      final first = sizes.first;
      if (first is Map && first['price'] != null) {
        return first['price'].toString();
      }
    }
    return '--';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset('assets/images/NewBeeLogoNBG.png', height: 60),
            const SizedBox(width: 10,),
            Expanded(
              child: Text("HoneyStore",
              style: TextStyle(
                color: Color(0xFFFFD54F),
                fontWeight: FontWeight.bold,
              ),
              ),
            )
          ],
        ),
        backgroundColor: Colors.brown[800],
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFFFD54F)),
      ),
      body: Stack(
        children: [
          // Background overlay
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    "Hi, ${widget.firstName}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // SEARCH BAR
                _glassCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: "Search products...",
                        border: InputBorder.none,
                        suffixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.trim().toLowerCase();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // CATEGORY FILTERS
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final selected = cat == selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: ChoiceChip(
                          label: Text(
                            cat,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.brown[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: selected,
                          selectedColor: Colors.brown[800],
                          showCheckmark: false, // ✅ Remove the checkmark
                          onSelected: (_) {
                            setState(() {
                              selectedCategory = cat;
                            });
                          },
                          backgroundColor: Colors.brown[100]?.withOpacity(0.2),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // PRODUCT GRID
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: getProducts(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final allDocs = snapshot.data!.docs;

                      // Filter by category
                      final categoryFiltered = selectedCategory == 'All'
                          ? allDocs
                          : allDocs.where((doc) {
                        final data =
                        doc.data() as Map<String, dynamic>;
                        final category =
                        (data['category'] ?? '').toString().toLowerCase();
                        return category ==
                            selectedCategory.toLowerCase();
                      }).toList();

                      // Filter by search query
                      final searchFiltered = searchQuery.isEmpty
                          ? categoryFiltered
                          : categoryFiltered.where((doc) {
                        final data =
                        doc.data() as Map<String, dynamic>;
                        final productName =
                        (data['name'] ?? '').toString().toLowerCase();
                        return productName.startsWith(searchQuery) ||
                            productName == searchQuery;
                      }).toList();

                      if (searchFiltered.isEmpty) {
                        return const Center(child: Text("No matching products."));
                      }

                      return GridView.builder(
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: searchFiltered.length,
                        itemBuilder: (context, index) {
                          final data =
                          searchFiltered[index].data() as Map<String, dynamic>;
                          final imageUrl =
                          (data['image_urls'] as List).isNotEmpty
                              ? data['image_urls'][0]
                              : '';
                          final productName = data['name'] ?? '';
                          final price = _getPrice(data);

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductDetailsScreen(product: data),
                                ),
                              );
                            },
                            child: _glassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: imageUrl.isNotEmpty
                                          ? Image.network(
                                        imageUrl,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.broken_image,
                                            size: 48),
                                      )
                                          : Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image,
                                            size: 48),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          productName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text("GHS $price"),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
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

