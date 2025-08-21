/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class IdGeneratorScreen extends StatefulWidget {
  const IdGeneratorScreen({super.key});

  @override
  State<IdGeneratorScreen> createState() => _IdGeneratorScreenState();

}

class _IdGeneratorScreenState extends State<IdGeneratorScreen> {
  final ScrollController _scrollController = ScrollController();
  String selectedType = 'Bee Champion';
  String statusFilter = 'All';
  String onlineFilter = 'All';
  String typeFilter = 'All';
  List<Map<String, dynamic>> users = [];

  final List<String> userTypes = ['Bee Champion', 'Trainer Bee', 'Learner Bee'];
  final List<String> statuses = ['All', 'Activated', 'Inactive'];
  final List<String> onlineOptions = ['All', 'Online', 'Offline'];

  @override
  void dispose() {
    _scrollController.dispose();
        super.dispose();
  }

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('generated_ids').get();
    setState(() {
      users = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<String> generateCustomId(String type) async {
    String prefix;
    switch (type) {
      case 'Bee Champion':
        prefix = 'BC';
        break;
      case 'Trainer Bee':
        prefix = 'TB';
        break;
      case 'Learner Bee':
        prefix = 'LB';
        break;
      default:
        throw Exception('Unknown type: $type');
    }

    final counterRef = FirebaseFirestore.instance.collection('counters').doc(prefix);
    final snapshot = await counterRef.get();

    int lastNumber = 0;
    if (snapshot.exists && snapshot.data()!.containsKey('last')) {
      lastNumber = snapshot['last'];
    }

    final newNumber = lastNumber + 1;
    final paddedNumber = newNumber.toString().padLeft(6, '0'); // BC000001

    // Update Firestore with new counter
    await counterRef.set({'last': newNumber}, SetOptions(merge: true));

    return '$prefix$paddedNumber';
  }


  String generateToken() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  void generateIdAndToken() async {
    final generatedUserId = await generateCustomId(selectedType);
    final token = generateToken();

    final docRef = await FirebaseFirestore.instance.collection('generated_ids').add({
      'generated_user_id': generatedUserId, // Custom formatted ID
      'token': token,
      'user_type': selectedType,
      'status': 'Not Activated',
      'online': false,
      'created_at': Timestamp.now(),
    });
    await docRef.update({'user_id': docRef.id});

    fetchUsers();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String tempStatus = statusFilter;
        String tempOnline = onlineFilter;
        String tempType = typeFilter;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Filter Users'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogDropdown('Status', statuses, tempStatus, (val) {
                    setStateDialog(() => tempStatus = val);
                  }),
                  _buildDialogDropdown('Online', onlineOptions, tempOnline, (val) {
                    setStateDialog(() => tempOnline = val);
                  }),
                  _buildDialogDropdown('User Type', ['All'] + userTypes, tempType, (val) {
                    setStateDialog(() => tempType = val);
                  }),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      statusFilter = tempStatus;
                      onlineFilter = tempOnline;
                      typeFilter = tempType;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Search'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Widget _buildDialogDropdown(String label, List<String> items, String currentValue, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          isExpanded: true,
          value: currentValue,
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: (val) => onChanged(val!),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _filteredUsers() {
    return users.where((user) {
      final matchStatus = statusFilter == 'All' || user['status'] == statusFilter;
      final matchOnline = onlineFilter == 'All' || (user['online'] ? 'Online' : 'Offline') == onlineFilter;
      final matchType = typeFilter == 'All' || user['user_type'] == typeFilter;
      return matchStatus && matchOnline && matchType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Users"), automaticallyImplyLeading: false,),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('User ID Generator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: selectedType,
                            items: userTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                            onChanged: (val) => setState(() => selectedType = val!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: generateIdAndToken,
                          child: const Text('Generate ID'),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                        const Text('All Users', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.filter_list_sharp),
                          onPressed: _showFilterDialog,
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 450,
                      child: Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: _filteredUsers().length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers()[index];
                            return ListTile(
                              leading: const Icon(Icons.person_outline),
                              title: Text(user['generated_user_id'] ?? ''),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Token: ${user['token'] ?? ''}'),
                                  Text('Status: ${user['status']}'),
                                  Text('${user['user_type']}'),
                                ],
                              ),
                              trailing: Text(user['online'] ? '🟢 Online' : '⚪ Offline'),
                            );
                          },
                        ),
                      ),
                      ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}


*/
import 'dart:math';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class IdGeneratorScreen extends StatefulWidget {
  const IdGeneratorScreen({super.key});

  @override
  State<IdGeneratorScreen> createState() => _IdGeneratorScreenState();
}

class _IdGeneratorScreenState extends State<IdGeneratorScreen> with SingleTickerProviderStateMixin {
  static const kScandalBrown = Color(0xFF8B4513);

  final ScrollController _scrollController = ScrollController();
  String selectedType = 'Bee Champion';
  String statusFilter = 'All';
  String onlineFilter = 'All';
  String typeFilter = 'All';
  List<Map<String, dynamic>> users = [];

  final List<String> userTypes = ['Bee Champion', 'Trainer Bee', 'Learner Bee'];
  final List<String> statuses = ['All', 'Activated', 'Inactive'];
  final List<String> onlineOptions = ['All', 'Online', 'Offline'];

  AnimationController? _controller;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller!, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller!, curve: Curves.easeIn),
    );

    _controller!.forward();
    fetchUsers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> fetchUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('generated_ids').get();
    setState(() {
      users = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<String> generateCustomId(String type) async {
    String prefix;
    switch (type) {
      case 'Bee Champion':
        prefix = 'BC';
        break;
      case 'Trainer Bee':
        prefix = 'TB';
        break;
      case 'Learner Bee':
        prefix = 'LB';
        break;
      default:
        throw Exception('Unknown type: $type');
    }

    final counterRef = FirebaseFirestore.instance.collection('counters').doc(prefix);
    final snapshot = await counterRef.get();

    int lastNumber = 0;
    if (snapshot.exists && snapshot.data()!.containsKey('last')) {
      lastNumber = snapshot['last'];
    }

    final newNumber = lastNumber + 1;
    final paddedNumber = newNumber.toString().padLeft(6, '0');

    await counterRef.set({'last': newNumber}, SetOptions(merge: true));

    return '$prefix$paddedNumber';
  }

  String generateToken() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  void generateIdAndToken() async {
    final generatedUserId = await generateCustomId(selectedType);
    final token = generateToken();

    final docRef = await FirebaseFirestore.instance.collection('generated_ids').add({
      'generated_user_id': generatedUserId,
      'token': token,
      'user_type': selectedType,
      'status': 'Not Activated',
      'online': false,
      'created_at': Timestamp.now(),
    });

    await docRef.update({'user_id': docRef.id});
    fetchUsers();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String tempStatus = statusFilter;
        String tempOnline = onlineFilter;
        String tempType = typeFilter;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            /*
            return Dialog(
              backgroundColor: Colors.transparent, // make outer dialog transparent
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.brown.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.brown.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Filter Users',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDialogDropdown('Status', statuses, tempStatus, (val) {
                          setStateDialog(() => tempStatus = val);
                        }),
                        _buildDialogDropdown('Online', onlineOptions, tempOnline, (val) {
                          setStateDialog(() => tempOnline = val);
                        }),
                        _buildDialogDropdown('User Type', ['All'] + userTypes, tempType, (val) {
                          setStateDialog(() => tempType = val);
                        }),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: kScandalBrown),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kScandalBrown,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  statusFilter = tempStatus;
                                  onlineFilter = tempOnline;
                                  typeFilter = tempType;
                                });
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'Search',
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
            );

             */
            return Dialog(
              backgroundColor: Colors.transparent, // Glass outer layer
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.brown.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.brown.withOpacity(0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Colors.white.withOpacity(0.6),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Title row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: const [
                                  Text(
                                    'Filter Users',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.brown,
                                    ),
                                  ),
                                  Icon(Icons.filter_list_sharp, color: Color(0xFF8B4513)),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Dropdowns
                              _buildDialogDropdown('Status', statuses, tempStatus, (val) {
                                setStateDialog(() => tempStatus = val);
                              }),
                              _buildDialogDropdown('Online', onlineOptions, tempOnline, (val) {
                                setStateDialog(() => tempOnline = val);
                              }),
                              _buildDialogDropdown('User Type', ['All'] + userTypes, tempType, (val) {
                                setStateDialog(() => tempType = val);
                              }),

                              const SizedBox(height: 20),

                              // Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(color: kScandalBrown),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kScandalBrown,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        statusFilter = tempStatus;
                                        onlineFilter = tempOnline;
                                        typeFilter = tempType;
                                      });
                                      Navigator.pop(context);
                                    },
                                    child: const Text(
                                      'Search',
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
                ),
              ),
            );

          },
        );
      },
    );
  }

  Widget _buildDialogDropdown(String label, List<String> items, String currentValue, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          isExpanded: true,
          value: currentValue,
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: (val) => onChanged(val!),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _filteredUsers() {
    return users.where((user) {
      final matchStatus = statusFilter == 'All' || user['status'] == statusFilter;
      final matchOnline = onlineFilter == 'All' || (user['online'] ? 'Online' : 'Offline') == onlineFilter;
      final matchType = typeFilter == 'All' || user['user_type'] == typeFilter;
      return matchStatus && matchOnline && matchType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Users",
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
        width: double.infinity,
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
            children: [
              if (_slideAnimation != null && _fadeAnimation != null)
                SlideTransition(
                  position: _slideAnimation!,
                  child: FadeTransition(
                    opacity: _fadeAnimation!,
                    child: _glassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('User ID Generator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: selectedType,
                                  items: userTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                                  onChanged: (val) => setState(() => selectedType = val!),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: generateIdAndToken,
                                style: ElevatedButton.styleFrom(backgroundColor: kScandalBrown),
                                child: Text('Generate ID', style: TextStyle(color: Colors.white),),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 30),
              if (_slideAnimation != null && _fadeAnimation != null)
                SlideTransition(
                  position: _slideAnimation!,
                  child: FadeTransition(
                    opacity: _fadeAnimation!,
                    child: _glassCard(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('All Users', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.filter_list_sharp),
                                onPressed: _showFilterDialog,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 450,
                            child: Scrollbar(
                              controller: _scrollController,
                              thumbVisibility: true,
                              child: ListView.builder(
                                controller: _scrollController,
                                itemCount: _filteredUsers().length,
                                itemBuilder: (context, index) {
                                  final user = _filteredUsers()[index];
                                  return ListTile(
                                    leading: const Icon(Icons.person_outline),
                                    title: Text(user['generated_user_id'] ?? ''),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Token: ${user['token'] ?? ''}'),
                                        Text('Status: ${user['status']}'),
                                        Text('Type: ${user['user_type']}'),
                                      ],
                                    ),
                                    trailing: Text(user['online'] ? '🟢 Online' : '⚪ Offline'),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.brown.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.brown.withOpacity(0.3)),
          ),
          child: child,
        ),
      ),
    );
  }
}
