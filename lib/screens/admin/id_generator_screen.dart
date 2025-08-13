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

  /*
  Future<String> generateCustomId(String type) async {
    final prefix = type == 'Bee Champion'
        ? 'BC'
        : type == 'Trainer Bee'
        ? 'TB'
        : 'LB';

    final counterRef = FirebaseFirestore.instance.collection('counters').doc(prefix);
    final snapshot = await counterRef.get();

    int lastNumber = 0;
    if (snapshot.exists && snapshot.data()!.containsKey('last')) {
      lastNumber = snapshot['last'];
    }

    final newNumber = lastNumber + 1;
    final paddedNumber = newNumber.toString().padLeft(6, '0');

    // Update Firestore with the new counter
    await counterRef.set({'last': newNumber}, SetOptions(merge: true));

    return '$prefix$paddedNumber';
  }

   */
  // Helper to generate BC/TB/LB format ID
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
/*
  void generateIdAndToken() async {
    final id = await generateUserId(selectedType);
    final token = generateToken();

    await FirebaseFirestore.instance.collection('generated_ids').doc(id).set({
      'user_id': id,
      'token': token,
      'user_type': selectedType,
      'status': 'Not Activated',
      'online': false,
      'created_at': Timestamp.now(),
    });

    fetchUsers();
  }

 */
  void generateIdAndToken() async {
    // Generate custom user ID (BC000001, TB000001, LB000001)
    final generatedUserId = await generateCustomId(selectedType);

    // Generate random token
    final token = generateToken();

    // Add a new document with Firestore's auto ID
    final docRef = await FirebaseFirestore.instance.collection('generated_ids').add({
      'generated_user_id': generatedUserId, // Custom formatted ID
      'token': token,
      'user_type': selectedType,
      'status': 'Not Activated',
      'online': false,
      'created_at': Timestamp.now(),
    });

    // If you want to also keep the auto ID in the document itself
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


