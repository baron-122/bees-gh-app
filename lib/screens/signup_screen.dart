/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _idCardNumberController = TextEditingController();
  final TextEditingController _userTokenController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();


  String username='';
  String? userIdFromToken;

  String? selectedGender;
  String? selectedRegion;
  String? selectedTown;
  String? selectedCommunity;
  String? selectedRole;
  String? selectedIdType;

  List<String> regions = [];
  List<String> towns = [];
  List<String> communities = [];

  final List<String> genders = ['Male', 'Female'];
  final List<String> roles = ['Client', 'Bee Champion', 'Trainer Bee', 'Learner Bee'];
  final List<String> idTypes = ['Ghana Card', 'Passport', "Voter's ID", "Driver's License"];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRegions();
    _firstNameController.addListener(_updateUsername);
    _lastNameController.addListener(_updateUsername);
  }

  void _updateUsername() {
    final first = _firstNameController.text.trim().toLowerCase();
    final last = _lastNameController.text.trim().toLowerCase();
    final generatedUsername = '$first.$last';
    setState(() {
      username = generatedUsername;
      _usernameController.text = generatedUsername;
    });
  }


  Future<void> _loadRegions() async {
    final snapshot = await FirebaseFirestore.instance.collection('regions').get();
    setState(() {
      regions = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Future<void> _loadTowns(String region) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('regions')
        .doc(region)
        .collection('towns')
        .get();

    setState(() {
      towns = snapshot.docs.map((doc) => doc.id).toList();
      selectedTown = null;
      selectedCommunity = null;
      communities = [];
    });
  }

  Future<void> _loadCommunities(String region, String town) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('regions')
        .doc(region)
        .collection('towns')
        .doc(town)
        .collection('communities')
        .get();

    setState(() {
      communities = snapshot.docs.map((doc) => doc['name'].toString()).toList();
      selectedCommunity = null;
    });
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final maxDate = DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: maxDate,
      firstDate: DateTime(1900),
      lastDate: maxDate,
    );
    if (picked != null) {
      _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  DocumentReference? matchedTokenDocRef;

  Future<void> _verifyAndAssignUserToken() async {
    final enteredToken = _userTokenController.text.trim();

    if (enteredToken.isEmpty) {
      throw Exception("Token is required.");
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('generated_ids')
        .where('token', isEqualTo: enteredToken)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception("No record found with this token.");
    }

    final doc = querySnapshot.docs.first;
    final data = doc.data();

    final storedToken = data['token'];
    final generatedUserId = data['generated_user_id'];

    if (storedToken == null || generatedUserId == null) {
      throw Exception("Token or User ID missing in the record.");
    }

    if (storedToken != enteredToken) {
      throw Exception("Invalid User ID Token.");
    }

    userIdFromToken = generatedUserId;
    matchedTokenDocRef = doc.reference;
  }


  Future<void> _signupUser() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedRegion == null || selectedTown == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select Region and Town")),
      );
      return;
    }

    // Token verification for non-client roles
    if (selectedRole != 'Client') {
      try {
        await _verifyAndAssignUserToken();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // Create Firebase Auth account
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final autoGeneratedUid = credential.user!.uid;

      // Base user data
      final userData = {
        'user_id': autoGeneratedUid, // always the Firestore document ID
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'region': selectedRegion,
        'town': selectedTown,
        'community': selectedCommunity,
        'gender': selectedGender,
        'role': selectedRole,
        'username': username,
        'created_at': FieldValue.serverTimestamp(),
        'status': selectedRole != 'Client' ? 'Activated' : 'Not Activated',
      };

      // Add extra info for special roles
      if (selectedRole != 'Client') {
        userData['id_type'] = selectedIdType;
        userData['id_number'] = _idCardNumberController.text.trim();
        userData['date_of_birth'] = _dobController.text.trim();
        userData['generated_user_id'] = userIdFromToken; // store the custom ID here
      }

      // Save to Firestore with UID as doc ID
      await FirebaseFirestore.instance.collection('users').doc(autoGeneratedUid).set(userData);

      // Update generated_ids status
      if (selectedRole != 'Client' && matchedTokenDocRef != null) {
        await matchedTokenDocRef!.update({
          'status': 'Activated',
          'assigned_to': autoGeneratedUid, // optional: link generated ID to user doc
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signup successful! Please login.")),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup failed: ${e.message}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Signup")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(labelText: "First Name"),
                          validator: (value) =>
                          RegExp(r"^[a-zA-Z-]+$").hasMatch(value ?? '') ? null : "Invalid first name",
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(labelText: "Last Name"),
                          validator: (value) =>
                          RegExp(r"^[a-zA-Z-]+$").hasMatch(value ?? '') ? null : "Invalid last name",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ToggleButtons(
                    isSelected: genders.map((g) => g == selectedGender).toList(),
                    children: genders.map((g) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(g),
                    )).toList(),
                    onPressed: (index) {
                      setState(() {
                        selectedGender = genders[index];
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: "User Group"),
                    items: roles
                        .map((group) => DropdownMenuItem(value: group, child: Text(group)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedRole = val),
                    validator: (val) => val == null ? "Please select user group" : null,
                  ),
                  const SizedBox(height: 10),
                  if (selectedRole != 'Client') ...[
                    TextFormField(
                      controller: _userTokenController,
                      decoration: const InputDecoration(labelText: "User ID Token"),
                      validator: (value) =>
                      value == null || value.isEmpty ? "Token required for this group" : null,
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedIdType,
                      decoration: const InputDecoration(labelText: "Type of Identification"),
                      items: idTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                      onChanged: (val) => setState(() => selectedIdType = val),
                    ),
                    TextFormField(
                      controller: _idCardNumberController,
                      decoration: const InputDecoration(labelText: "Identification Number"),
                    ),
                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      onTap: _pickDateOfBirth,
                      decoration: const InputDecoration(labelText: "Date of Birth"),
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: "Phone Number"),
                    validator: (value) =>
                    RegExp(r"^\+?[0-9]{7,15}$").hasMatch(value ?? '') ? null : "Invalid phone",
                  ),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: "Email"),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                    RegExp(r"^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(value ?? '')
                        ? null
                        : "Enter a valid email",
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedRegion,
                    decoration: const InputDecoration(labelText: "Select Region"),
                    items: regions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) {
                      if (val != selectedRegion) {
                        setState(() {
                          selectedRegion = val;
                          selectedTown = null;
                          selectedCommunity = null;
                          towns = [];
                          communities = [];
                        });
                        if (val != null) {
                          _loadTowns(val);
                        }
                      }
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedTown,
                    decoration: const InputDecoration(labelText: "Select Town"),
                    items: towns.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) {
                      if (val != selectedTown) {
                        setState(() {
                          selectedTown = val;
                          selectedCommunity = null;
                          communities = [];
                        });
                        if (selectedRegion != null && val != null) {
                          _loadCommunities(selectedRegion!, val);
                        }
                      }
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedCommunity,
                    decoration:
                    const InputDecoration(labelText: "Select Community (optional)"),
                    items:
                    communities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => selectedCommunity = val),
                  ),
                  TextFormField(
                    readOnly: true,
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: "Username",
                      suffixIcon: Icon(Icons.lock_outline),
                    ),
                  ),

                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: "Password"),
                    obscureText: true,
                    validator: (value) => RegExp(
                        r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$&*~]).{6,}")
                        .hasMatch(value ?? '')
                        ? null
                        : "Password must include upper, lower, number & symbol",
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _signupUser,
                    child: const Text("Sign Up"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}



*/
/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _idCardNumberController = TextEditingController();
  final TextEditingController _userTokenController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  String username = '';
  String? userIdFromToken;
  String? selectedGender;
  String? selectedRegion;
  String? selectedTown;
  String? selectedCommunity;
  String? selectedRole;
  String? selectedIdType;

  List<String> regions = [];
  List<String> towns = [];
  List<String> communities = [];

  final List<String> genders = ['Male', 'Female'];
  final List<String> roles = ['Client', 'Bee Champion', 'Trainer Bee', 'Learner Bee'];
  final List<String> idTypes = ['Ghana Card', 'Passport', "Voter's ID", "Driver's License"];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRegions();
    _firstNameController.addListener(_updateUsername);
    _lastNameController.addListener(_updateUsername);
  }

  void _updateUsername() {
    final first = _firstNameController.text.trim().toLowerCase();
    final last = _lastNameController.text.trim().toLowerCase();
    final generatedUsername = '$first.$last';
    setState(() {
      username = generatedUsername;
      _usernameController.text = generatedUsername;
    });
  }

  Future<void> _loadRegions() async {
    final snapshot = await FirebaseFirestore.instance.collection('regions').get();
    setState(() {
      regions = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Future<void> _loadTowns(String region) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('regions')
        .doc(region)
        .collection('towns')
        .get();

    setState(() {
      towns = snapshot.docs.map((doc) => doc.id).toList();
      selectedTown = null;
      selectedCommunity = null;
      communities = [];
    });
  }

  Future<void> _loadCommunities(String region, String town) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('regions')
        .doc(region)
        .collection('towns')
        .doc(town)
        .collection('communities')
        .get();

    setState(() {
      communities = snapshot.docs.map((doc) => doc['name'].toString()).toList();
      selectedCommunity = null;
    });
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final maxDate = DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: maxDate,
      firstDate: DateTime(1900),
      lastDate: maxDate,
    );
    if (picked != null) {
      _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  DocumentReference? matchedTokenDocRef;

  Future<void> _verifyAndAssignUserToken() async {
    final enteredToken = _userTokenController.text.trim();

    if (enteredToken.isEmpty) {
      throw Exception("Token is required.");
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('generated_ids')
        .where('token', isEqualTo: enteredToken)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception("No record found with this token.");
    }

    final doc = querySnapshot.docs.first;
    final data = doc.data();

    final storedToken = data['token'];
    final generatedUserId = data['generated_user_id'];

    if (storedToken == null || generatedUserId == null) {
      throw Exception("Token or User ID missing in the record.");
    }

    if (storedToken != enteredToken) {
      throw Exception("Invalid User ID Token.");
    }

    userIdFromToken = generatedUserId;
    matchedTokenDocRef = doc.reference;
  }

  Future<void> _signupUser() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedRegion == null || selectedTown == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select Region and Town")),
      );
      return;
    }

    if (selectedRole != 'Client') {
      try {
        await _verifyAndAssignUserToken();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final autoGeneratedUid = credential.user!.uid;

      final userData = {
        'user_id': autoGeneratedUid,
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'region': selectedRegion,
        'town': selectedTown,
        'community': selectedCommunity,
        'gender': selectedGender,
        'role': selectedRole,
        'username': username,
        'created_at': FieldValue.serverTimestamp(),
        'status': selectedRole != 'Client' ? 'Activated' : 'Not Activated',
      };

      if (selectedRole != 'Client') {
        userData['id_type'] = selectedIdType;
        userData['id_number'] = _idCardNumberController.text.trim();
        userData['date_of_birth'] = _dobController.text.trim();
        userData['generated_user_id'] = userIdFromToken;
      }

      await FirebaseFirestore.instance.collection('users').doc(autoGeneratedUid).set(userData);

      if (selectedRole != 'Client' && matchedTokenDocRef != null) {
        await matchedTokenDocRef!.update({
          'status': 'Activated',
          'assigned_to': autoGeneratedUid,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signup successful! Please login.")),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup failed: ${e.message}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool obscure = false,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      validator: validator,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        prefixIcon: icon != null ? Icon(icon, color: Colors.brown.shade700) : null,
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: Colors.white.withOpacity(0.9),
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Join the Buzzing Family",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _firstNameController,
                              label: "First Name",
                              icon: Icons.person,
                              validator: (v) => RegExp(r"^[a-zA-Z-]+$").hasMatch(v ?? '') ? null : "Invalid",
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _lastNameController,
                              label: "Last Name",
                              icon: Icons.person_outline,
                              validator: (v) => RegExp(r"^[a-zA-Z-]+$").hasMatch(v ?? '') ? null : "Invalid",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ToggleButtons(
                        borderRadius: BorderRadius.circular(12),
                        selectedColor: Colors.white,
                        fillColor: Colors.brown,
                        isSelected: genders.map((g) => g == selectedGender).toList(),
                        children: genders.map((g) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(g),
                        )).toList(),
                        onPressed: (index) {
                          setState(() {
                            selectedGender = genders[index];
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: InputDecoration(
                          labelText: "User Group",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: roles
                            .map((group) => DropdownMenuItem(value: group, child: Text(group)))
                            .toList(),
                        onChanged: (val) => setState(() => selectedRole = val),
                        validator: (val) => val == null ? "Required" : null,
                      ),
                      if (selectedRole != 'Client') ...[
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: _userTokenController,
                          label: "User ID Token",
                          icon: Icons.key,
                          validator: (v) => v == null || v.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: selectedIdType,
                          decoration: InputDecoration(
                            labelText: "Type of Identification",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: idTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                          onChanged: (val) => setState(() => selectedIdType = val),
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: _idCardNumberController,
                          label: "Identification Number",
                          icon: Icons.credit_card,
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: _dobController,
                          label: "Date of Birth",
                          icon: Icons.cake,
                          readOnly: true,
                          onTap: _pickDateOfBirth,
                        ),
                      ],
                      const SizedBox(height: 10),
                      _buildTextField(
                        controller: _phoneController,
                        label: "Phone Number",
                        icon: Icons.phone,
                        validator: (v) => RegExp(r"^\+?[0-9]{7,15}$").hasMatch(v ?? '') ? null : "Invalid",
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        controller: _emailController,
                        label: "Email",
                        icon: Icons.email,
                        type: TextInputType.emailAddress,
                        validator: (v) => RegExp(r"^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(v ?? '') ? null : "Invalid",
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedRegion,
                        decoration: InputDecoration(
                          labelText: "Select Region",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: regions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                        onChanged: (val) {
                          if (val != selectedRegion) {
                            setState(() {
                              selectedRegion = val;
                              selectedTown = null;
                              selectedCommunity = null;
                              towns = [];
                              communities = [];
                            });
                            if (val != null) {
                              _loadTowns(val);
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedTown,
                        decoration: InputDecoration(
                          labelText: "Select Town",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: towns.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) {
                          if (val != selectedTown) {
                            setState(() {
                              selectedTown = val;
                              selectedCommunity = null;
                              communities = [];
                            });
                            if (selectedRegion != null && val != null) {
                              _loadCommunities(selectedRegion!, val);
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedCommunity,
                        decoration: InputDecoration(
                          labelText: "Select Community (optional)",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: communities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) => setState(() => selectedCommunity = val),
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        controller: _usernameController,
                        label: "Username",
                        icon: Icons.lock_outline,
                        readOnly: true,
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        controller: _passwordController,
                        label: "Password",
                        icon: Icons.lock,
                        obscure: true,
                        validator: (v) => RegExp(r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$&*~]).{6,}")
                            .hasMatch(v ?? '')
                            ? null
                            : "Must include upper, lower, number & symbol",
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _signupUser,
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(
                                  color: Colors.brown,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
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
  }
}
*/
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // -----------------------------
  // THEME (match your Login page)
  // -----------------------------
  static const Color _honeyStart = Color(0xFFFFD54F); // warm honey
  static const Color _honeyEnd   = Color(0xFFFFA726); // orange/gold
  static const Color _deepBrown  = Color(0xFF4E342E); // deep bee brown
  static const Color _cardBorder = Color(0x33FFFFFF);

  // Button gradient (golden)
  static const List<Color> _btnGrad = [Color(0xFFFFE082), Color(0xFFFFB300)];

  // -----------------------------
  // FORM STATE
  // -----------------------------
  final _formKey = GlobalKey<FormState>();

  // Step control
  int _currentStep = 0; // 0: Personal, 1: Contact, 2: User

  // Controllers
  final TextEditingController _firstNameController     = TextEditingController();
  final TextEditingController _lastNameController      = TextEditingController();
  final TextEditingController _emailController         = TextEditingController();
  final TextEditingController _phoneController         = TextEditingController();
  final TextEditingController _passwordController      = TextEditingController();
  final TextEditingController _dobController           = TextEditingController();
  final TextEditingController _idCardNumberController  = TextEditingController();
  final TextEditingController _userTokenController     = TextEditingController();
  final TextEditingController _usernameController      = TextEditingController();

  // Values
  String username = '';
  String? userIdFromToken; // custom ID read from generated_ids
  String? selectedGender;
  String? selectedRegion;
  String? selectedTown;
  String? selectedCommunity;
  String? selectedRole = 'Client'; // default to Client
  String? selectedIdType;

  // Data sources
  List<String> regions = [];
  List<String> towns = [];
  List<String> communities = [];

  final List<String> genders = ['Male', 'Female'];
  final List<String> roles = ['Client', 'Bee Champion', 'Trainer Bee', 'Learner Bee'];
  final List<String> idTypes = ['Ghana Card', 'Passport', "Voter's ID", "Driver's License"];

  bool _isLoading = false;
  DocumentReference? matchedTokenDocRef;

  @override
  void initState() {
    super.initState();
    _loadRegions();
    _firstNameController.addListener(_updateUsername);
    _lastNameController.addListener(_updateUsername);
  }

  // -----------------------------
  // HELPERS & LOADERS
  // -----------------------------
  void _updateUsername() {
    final first = _firstNameController.text.trim().toLowerCase();
    final last  = _lastNameController.text.trim().toLowerCase();
    final generatedUsername = [
      if (first.isNotEmpty) first,
      if (last.isNotEmpty) last,
    ].join('.');
    setState(() {
      username = generatedUsername;
      _usernameController.text = generatedUsername;
    });
  }

  Future<void> _loadRegions() async {
    final snapshot = await FirebaseFirestore.instance.collection('regions').get();
    setState(() {
      regions = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Future<void> _loadTowns(String region) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('regions')
        .doc(region)
        .collection('towns')
        .get();
    setState(() {
      towns = snapshot.docs.map((doc) => doc.id).toList();
      selectedTown = null;
      selectedCommunity = null;
      communities = [];
    });
  }

  Future<void> _loadCommunities(String region, String town) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('regions')
        .doc(region)
        .collection('towns')
        .doc(town)
        .collection('communities')
        .get();
    setState(() {
      communities = snapshot.docs.map((doc) => doc['name'].toString()).toList();
      selectedCommunity = null;
    });
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final maxDate = DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: maxDate,
      firstDate: DateTime(1900),
      lastDate: maxDate,
    );
    if (picked != null) {
      _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _verifyAndAssignUserToken() async {
    final enteredToken = _userTokenController.text.trim();
    if (enteredToken.isEmpty) {
      throw Exception("Token is required.");
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('generated_ids')
        .where('token', isEqualTo: enteredToken)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception("No record found with this token.");
    }

    final doc  = querySnapshot.docs.first;
    final data = doc.data();

    final storedToken     = data['token'];
    final generatedUserId = data['generated_user_id'];

    if (storedToken == null || generatedUserId == null) {
      throw Exception("Token or User ID missing in the record.");
    }
    if (storedToken != enteredToken) {
      throw Exception("Invalid User ID Token.");
    }

    userIdFromToken   = generatedUserId; // custom ID string like BC000001
    matchedTokenDocRef = doc.reference;  // generated_ids/<autoDocId>
  }

  // -----------------------------
  // VALIDATION PER STEP
  // -----------------------------
  bool _validateStep(int step) {
    String? err;

    if (step == 0) {
      final fn = _firstNameController.text.trim();
      final ln = _lastNameController.text.trim();
      if (!RegExp(r"^[a-zA-Z-]+$").hasMatch(fn)) err = "Enter a valid first name";
      else if (!RegExp(r"^[a-zA-Z-]+$").hasMatch(ln)) err = "Enter a valid last name";
      else if (selectedGender == null) err = "Please select gender";
      else if (selectedRegion == null) err = "Please select region";
      else if (selectedTown == null) err = "Please select town";
      // Community optional; skip.
    } else if (step == 1) {
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();
      if (!RegExp(r"^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email)) err = "Enter a valid email";
      else if (!RegExp(r"^\+?[0-9]{7,15}$").hasMatch(phone)) err = "Enter a valid phone";
    } else if (step == 2) {
      if (selectedRole == null) {
        err = "Please select user group";
      } else {
        if (selectedRole == 'Client') {
          if (_passwordController.text.isEmpty) {
            err = "Password required";
          } else if (!RegExp(r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$&*~]).{6,}$")
              .hasMatch(_passwordController.text)) {
            err = "Password must include upper, lower, number & symbol";
          }
        } else {
          if (_userTokenController.text.trim().isEmpty) err = "Token required";
          else if (selectedIdType == null) err = "Select ID type";
          else if (_idCardNumberController.text.trim().isEmpty) err = "Enter ID number";
          else if (_dobController.text.trim().isEmpty) err = "Select date of birth";
          else if (_passwordController.text.isEmpty) err = "Password required";
          else if (!RegExp(r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$&*~]).{6,}$")
              .hasMatch(_passwordController.text)) {
            err = "Password must include upper, lower, number & symbol";
          }
        }
      }
    }

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return false;
    }
    return true;
  }

  // -----------------------------
  // NAVIGATION BETWEEN STEPS
  // -----------------------------
  void _goNext() async {
    if (!_validateStep(_currentStep)) return;

    if (_currentStep < 2) {
      setState(() => _currentStep += 1);
      return;
    }

    // Last step -> submit
    await _signupUser();
  }

  void _goBack() {
    if (_currentStep > 0) setState(() => _currentStep -= 1);
  }

  // -----------------------------
  // SIGNUP LOGIC
  // -----------------------------
  Future<void> _signupUser() async {
    if (selectedRegion == null || selectedTown == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select Region and Town")),
      );
      return;
    }

    // Token verification for non-Client roles
    if (selectedRole != 'Client') {
      try {
        await _verifyAndAssignUserToken();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      // Create Firebase Auth account
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final autoGeneratedUid = credential.user!.uid;

      // Base user data
      final Map<String, dynamic> userData = {
        'user_id'   : autoGeneratedUid, // always the Firestore user doc ID (Auth UID)
        'first_name': _firstNameController.text.trim(),
        'last_name' : _lastNameController.text.trim(),
        'email'     : _emailController.text.trim(),
        'phone'     : _phoneController.text.trim(),
        'region'    : selectedRegion,
        'town'      : selectedTown,
        'community' : selectedCommunity,
        'gender'    : selectedGender,
        'role'      : selectedRole,
        'username'  : username,
        'created_at': FieldValue.serverTimestamp(),
        'status'    : selectedRole != 'Client' ? 'Activated' : 'Not Activated',
      };

      // Extra info for roles beyond Client
      if (selectedRole != 'Client') {
        userData['id_type']          = selectedIdType;
        userData['id_number']        = _idCardNumberController.text.trim();
        userData['date_of_birth']    = _dobController.text.trim();
        userData['generated_user_id'] = userIdFromToken; // custom readable ID (BC/TB/LB…)
      }

      // Save to Firestore with UID as doc ID
      await FirebaseFirestore.instance.collection('users').doc(autoGeneratedUid).set(userData);

      // Update generated_ids: mark Activated and link to UID
      if (selectedRole != 'Client' && matchedTokenDocRef != null) {
        await matchedTokenDocRef!.update({
          'status'     : 'Activated',
          'assigned_to': autoGeneratedUid,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signup successful! Please login.")),
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup failed: ${e.message}")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // -----------------------------
  // UI BUILDERS
  // -----------------------------
  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _deepBrown),
      filled: true,
      fillColor: Colors.white.withOpacity(1.0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _deepBrown, width: 1),
      ),
      labelStyle: const TextStyle(color: _deepBrown),
    );
  }

  Widget _gradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFC107), Color(0xFFFFA000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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

  Widget _stepHeader() {
    final titles = ["Personal Information", "Contact Information", "User"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.supervised_user_circle, size: 60, color: Colors.brown[800]),
        Text(
          "Join the Buzzing Family",
          style: const TextStyle(
            color: _deepBrown,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Step ${_currentStep + 1} of 3 — ${titles[_currentStep]}",
          style: TextStyle(
            color: _deepBrown.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _honeyButton({
    required String label,
    required VoidCallback onPressed,
    bool expand = true,
    bool loading = false,
  }) {
    final btnChild = loading
        ? const SizedBox(
        height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
        : Text(
      label,
      style: const TextStyle(
        color: _deepBrown,
        fontWeight: FontWeight.w800,
        fontSize: 16,
        letterSpacing: 0.2,
      ),
    );

    final button = InkWell(
      onTap: loading ? null : onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: _btnGrad,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(child: btnChild),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _ghostButton({required String label, required VoidCallback onPressed}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: _deepBrown,
        side: BorderSide(color: _deepBrown.withOpacity(0.6)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }

  // -----------------------------
  // STEP CONTENT
  // -----------------------------
  Widget _personalInfoStep() {
    return Column(
      children: [
        const SizedBox(height: 20),
        TextField(
          controller: _firstNameController,
          decoration: _decoration("First Name", Icons.person)

        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: _lastNameController,
          decoration: _decoration("Last Name", Icons.person),
        ),
        const SizedBox(height: 15),
        DropdownButtonFormField<String>(
          value: selectedGender,
          items: genders
              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
              .toList(),
          onChanged: (val) => setState(() => selectedGender = val),
          decoration: _decoration("Gender", Icons.wc),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: selectedRegion,
          items: regions
              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
              .toList(),
          onChanged: (val) {
            if (val != selectedRegion) {
              setState(() {
                selectedRegion = val;
                selectedTown = null;
                selectedCommunity = null;
                towns = [];
                communities = [];
              });
              if (val != null) _loadTowns(val);
            }
          },
          decoration: _decoration("Region", Icons.map_outlined),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: selectedTown,
          items: towns
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (val) {
            if (val != selectedTown) {
              setState(() {
                selectedTown = val;
                selectedCommunity = null;
                communities = [];
              });
              if (selectedRegion != null && val != null) {
                _loadCommunities(selectedRegion!, val);
              }
            }
          },
          decoration: _decoration("Town", Icons.location_city_outlined),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: selectedCommunity,
          items: communities
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (val) => setState(() => selectedCommunity = val),
          decoration: _decoration("Community (optional)", Icons.people_alt_outlined),
        ),
      ],
    );
  }

  Widget _contactInfoStep() {
    return Column(
      children: [
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _decoration("Email", Icons.email_outlined),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: _decoration("Phone Number", Icons.phone_outlined),
        ),
      ],
    );
  }

  Widget _userStep() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: selectedRole,
          items: roles
              .map((role) => DropdownMenuItem(value: role, child: Text(role)))
              .toList(),
          onChanged: (val) => setState(() => selectedRole = val),
          decoration: _decoration("User Group", Icons.groups_2_outlined),
        ),
        const SizedBox(height: 12),

        // If Client: only username + password
        if (selectedRole == 'Client') ...[
          TextFormField(
            controller: _usernameController,
            readOnly: true,
            decoration: _decoration("Username (auto)", Icons.person_outline),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: _decoration("Password", Icons.lock_outline),
          ),
        ] else ...[
          TextFormField(
            controller: _userTokenController,
            decoration: _decoration("User ID Token", Icons.vpn_key_outlined),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedIdType,
            items: idTypes
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (val) => setState(() => selectedIdType = val),
            decoration: _decoration("Type of Identification", Icons.credit_card),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _idCardNumberController,
            decoration: _decoration("Identification Number", Icons.confirmation_num_outlined),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickDateOfBirth,
            child: AbsorbPointer(
              child: TextFormField(
                controller: _dobController,
                decoration: _decoration("Date of Birth", Icons.calendar_today_outlined),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _usernameController,
            readOnly: true,
            decoration: _decoration("Username (auto)", Icons.person_outline),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: _decoration("Password", Icons.lock_outline),
          ),
        ],
      ],
    );
  }

  Widget _stepContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(anim),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: Column(
        key: ValueKey(_currentStep),
        children: [
          if (_currentStep == 0) _personalInfoStep(),
          if (_currentStep == 1) _contactInfoStep(),
          if (_currentStep == 2) _userStep(),
        ],
      ),
    );
  }

  Widget _stepButtons() {
    final isLast = _currentStep == 2;

    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: ElevatedButton(
              onPressed: _goBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513), // Brown
                foregroundColor: Colors.white, // White text
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Back",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        else
          const Expanded(child: SizedBox.shrink()),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _goNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513), // Brown
              foregroundColor: Colors.white, // White text
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
              height: 15,
              width: 10,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Text(
              isLast ? "Sign Up" : "Next",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }


  // -----------------------------
  // BUILD
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No AppBar: title is inside the card (to match your login)
      body: Stack(
        children: [
          _gradientBackground(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: _glassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _stepHeader(),
                          const SizedBox(height: 16),
                          _stepContent(),
                          const SizedBox(height: 18),
                          _stepButtons(),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                            child: const Text(
                              "Already have an account? Log in",
                              style: TextStyle(
                                color: _deepBrown,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------
  // DISPOSE
  // -----------------------------
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    _idCardNumberController.dispose();
    _userTokenController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
}

