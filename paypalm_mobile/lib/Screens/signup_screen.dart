import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _icController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _verificationId;
  bool _codeSent = false;
  bool _isLoading = false;
  String? _qrData;
  bool _hasPalmHash = false;

  @override 
  void initState() {
    super.initState();
    debugPrint('SignupScreen: initState called');
    _checkAuthAndPalmHash();
  }

  Future<void> _checkAuthAndPalmHash() async {
    debugPrint('SignupScreen: Checking auth and palmhash');
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('SignupScreen: Current user: $user');
    if (user != null) {
      // Check if palmhash exists in Firestore
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final palmhash = doc.data()?['palmhash'];
      debugPrint('SignupScreen: palmhash value: $palmhash');
      if (palmhash != null && palmhash.toString().isNotEmpty) {
        setState(() {
          _hasPalmHash = true;
        });
        debugPrint('SignupScreen: User has palmhash, setting _hasPalmHash = true');
      } else {
        setState(() {
          _qrData = _buildQRData(user.uid);
        });
        debugPrint('SignupScreen: No palmhash, setting _qrData');
      }
    }
  }

  String _buildQRData(String uid) {
    final data = '{"uid":"$uid","name":"${_nameController.text}","ic":"${_icController.text}"}';
    debugPrint('SignupScreen: Building QR data: $data');
    return data;
  }

  Future<void> _verifyPhone() async {
    setState(() => _isLoading = true);
    debugPrint('SignupScreen: Starting phone verification for ${_phoneController.text}');
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _phoneController.text,
      verificationCompleted: (PhoneAuthCredential credential) async {
        debugPrint('SignupScreen: verificationCompleted');
        await FirebaseAuth.instance.signInWithCredential(credential);
        setState(() {
          _qrData = _buildQRData(FirebaseAuth.instance.currentUser!.uid);
          _isLoading = false;
        });
        debugPrint('SignupScreen: Signed in with credential, QR data set');
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);
        debugPrint('SignupScreen: verificationFailed: ${e.message}');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Verification failed')));
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _codeSent = true;
          _isLoading = false;
        });
        debugPrint('SignupScreen: codeSent, verificationId: $verificationId');
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        setState(() => _isLoading = false);
        debugPrint('SignupScreen: codeAutoRetrievalTimeout');
      },
    );
  }

  Future<void> _signInWithCode(String smsCode) async {
    setState(() => _isLoading = true);
    debugPrint('SignupScreen: Signing in with SMS code: $smsCode');
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      setState(() {
        _qrData = _buildQRData(FirebaseAuth.instance.currentUser!.uid);
        _isLoading = false;
      });
      debugPrint('SignupScreen: Signed in with SMS code, QR data set');
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('SignupScreen: Error signing in with SMS code: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid code')));
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('SignupScreen: build called, _hasPalmHash=$_hasPalmHash, _qrData=$_qrData');
    if (_hasPalmHash) {
      return Scaffold(
        appBar: AppBar(title: const Text('PalmPay')),
        body: const Center(
          child: Text('You are registered and connected to PalmHash.'),
        ),
      );
    }

    if (_qrData != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your QR Code')),
        body: Center(
          child: QrImageView(
            data: _qrData!,
            version: QrVersions.auto,
            size: 250.0,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (v) => v == null || v.isEmpty ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _icController,
                      decoration: const InputDecoration(labelText: 'IC Number'),
                      validator: (v) => v == null || v.isEmpty ? 'Enter your IC' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone Number (+60...)'),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.isEmpty ? 'Enter your phone number' : null,
                    ),
                    const SizedBox(height: 24),
                    if (!_codeSent)
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            debugPrint('SignupScreen: Verify Phone button pressed');
                            _verifyPhone();
                          }
                        },
                        child: const Text('Verify Phone'),
                      ),
                    if (_codeSent)
                      Column(
                        children: [
                          TextFormField(
                            decoration: const InputDecoration(labelText: 'SMS Code'),
                            keyboardType: TextInputType.number,
                            onChanged: (code) {
                              debugPrint('SignupScreen: SMS code entered: $code');
                              if (code.length == 6) {
                                _signInWithCode(code);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                debugPrint('SignupScreen: Submit Code button pressed');
                                // User will enter code above
                              }
                            },
                            child: const Text('Submit Code'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}