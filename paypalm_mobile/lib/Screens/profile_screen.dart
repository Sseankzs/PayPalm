import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:math';
import 'dart:async';

class ProfileScreen extends StatefulWidget {
  final String uid;
  final String email;
  const ProfileScreen({super.key, required this.uid, required this.email});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? fullName;
  String? icNumber;
  String? email;
  String? palmHash;
  bool isLoading = true;
  String? sessionId;
  bool showPalmHashError = false;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    setState(() => isLoading = true);
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
    final data = doc.data();
    if (data != null) {
      fullName = data['fullName'];
      icNumber = data['icNumber'];
      email = data['email'] ?? widget.email;
      palmHash = data['palmHash'];
      if (palmHash == null) {
        // Show error for 3 seconds if palmHash does not exist
        setState(() => showPalmHashError = true);
        Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => showPalmHashError = false);
        });
      }
    } else {
      email = widget.email;
      palmHash = null;
      setState(() => showPalmHashError = true);
      Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => showPalmHashError = false);
      });
    }
    setState(() => isLoading = false);
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
      'fullName': fullName,
      'icNumber': icNumber,
      'email': email,
      'palmHash': null,
    }, SetOptions(merge: true));
    await _fetchUser();
  }

  Future<void> _generatePalmQR() async {
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(minutes: 10));
    sessionId = '${widget.uid}_${now.millisecondsSinceEpoch}_${Random().nextInt(99999)}';
    await FirebaseFirestore.instance.collection('linkRequests').doc(sessionId).set({
      'uid': widget.uid,
      'mode': 'linkPalm',
      'timestamp': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(expiresAt),
    });
    _showQRDialog();
  }

  void _showQRDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Palm Link QR', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              QrImageView(
                data: widget.uid,
                size: 300,
              ),
              const SizedBox(height: 16),
              Text('Scan this QR with your palm device to link.', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _payPalmModeToggle() {
    final isOn = palmHash != null;
    return Padding(
      padding: const EdgeInsets.only(top: 32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'PayPalm Mode: ',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            isOn ? 'ON' : 'OFF',
            style: TextStyle(
              color: isOn ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: isOn,
            activeColor: Colors.green,
            inactiveThumbColor: Colors.red,
            onChanged: (val) async {
              setState(() => isLoading = true);
              await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
                'palmHash': val ? 'dummyPalmHash' : null,
              });
              await _fetchUser();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isPalmLinked = palmHash != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (isPalmLinked)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Icon(Icons.fingerprint, color: Colors.indigo),
                  const SizedBox(width: 6),
                  Text(
                    'PayPalm Mode Activated',
                    style: TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (showPalmHashError)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  'palmHash does not exist!',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            Expanded(
              child: isPalmLinked
                  ? Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.indigo,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(fullName ?? '-', style: Theme.of(context).textTheme.titleMedium),
                              subtitle: Text('Palm linked', style: TextStyle(color: Colors.green)),
                              trailing: Icon(Icons.verified, color: Colors.green),
                            ),
                            const Divider(),
                            ListTile(
                              leading: Icon(Icons.credit_card),
                              title: Text('IC Number'),
                              subtitle: Text(icNumber ?? '-'),
                            ),
                            ListTile(
                              leading: Icon(Icons.email),
                              title: Text('Email'),
                              subtitle: Text(email ?? '-'),
                            ),
                            const SizedBox(height: 24),
                            _payPalmModeToggle(), // <-- Add here
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    TextFormField(
                                      initialValue: fullName,
                                      decoration: const InputDecoration(
                                        labelText: 'Full Name',
                                        prefixIcon: Icon(Icons.person),
                                      ),
                                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                      onSaved: (v) => fullName = v,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      initialValue: icNumber,
                                      decoration: const InputDecoration(
                                        labelText: 'IC Number',
                                        prefixIcon: Icon(Icons.credit_card),
                                      ),
                                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                      onSaved: (v) => icNumber = v,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      initialValue: email,
                                      decoration: const InputDecoration(
                                        labelText: 'Email',
                                        prefixIcon: Icon(Icons.email),
                                      ),
                                      enabled: false,
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.save),
                                        label: const Text('Save'),
                                        onPressed: _saveUser,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.qr_code),
                                  label: const Text('Generate Palm Link QR'),
                                  onPressed: _generatePalmQR,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _payPalmModeToggle(), // <-- Add here
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}