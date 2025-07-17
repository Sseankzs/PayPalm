import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:math';

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
  bool showQR = false;
  String? sessionId;

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
      email = data['email'];
      palmHash = data['palmHash'];
    } else {
      email = FirebaseAuth.instance.currentUser?.email ?? '';
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
    setState(() {});
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
    setState(() {
      showQR = true;
    });
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
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isPalmLinked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Full Name: ${fullName ?? '-'}', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('IC Number: ${icNumber ?? '-'}'),
                  const SizedBox(height: 8),
                  Text('Email: ${email ?? '-'}'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text('Palm linked', style: TextStyle(color: Colors.green)),
                    ],
                  ),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            initialValue: fullName,
                            decoration: const InputDecoration(labelText: 'Full Name'),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            onSaved: (v) => fullName = v,
                          ),
                          TextFormField(
                            initialValue: icNumber,
                            decoration: const InputDecoration(labelText: 'IC Number'),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            onSaved: (v) => icNumber = v,
                          ),
                          TextFormField(
                            initialValue: email,
                            decoration: const InputDecoration(labelText: 'Email'),
                            enabled: false,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _saveUser,
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _generatePalmQR,
                      child: const Text('Generate Palm Link QR'),
                    ),
                    if (showQR && sessionId != null) ...[
                      const SizedBox(height: 24),
                      Center(
                        child: QrImageView(
                          data: sessionId!,
                          size: 200,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Scan this QR with your palm device to link.', textAlign: TextAlign.center),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}