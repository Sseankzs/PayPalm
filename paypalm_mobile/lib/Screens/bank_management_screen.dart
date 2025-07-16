import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BankManagementScreen extends StatelessWidget {
  const BankManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = 'uZsYmasM5B3dVXTYjt3J';
    final accountsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('linkedAccounts');
    final currencyFormat = NumberFormat.currency(symbol: "RM ");

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Linked Accounts')),
      body: StreamBuilder<QuerySnapshot>(
        stream: accountsRef.snapshots(),
        builder: (context, snapshot) {
          debugPrint('BankManagementScreen: Firestore snapshot has data: ${snapshot.hasData}, error: ${snapshot.error}');
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No linked accounts.'));
          }

          // Calculate total assets
          double totalAssets = 0;
          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            totalAssets += (data['balance'] ?? 0).toDouble();
          }

          // Separate default and non-default banks
          final defaultBankDocs = docs.where((d) => d['isDefault'] == true).toList();
          final otherBankDocs = docs.where((d) => d['isDefault'] != true).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total Assets
              Container(
                width: double.infinity,
                color: Colors.indigo.shade50,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Assets',
                      style: TextStyle(fontSize: 18, color: Colors.indigo, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(totalAssets),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Default Bank Section
              if (defaultBankDocs.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Default Bank',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade700,
                      fontSize: 16,
                    ),
                  ),
                ),
                ...defaultBankDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Card(
                    color: Colors.amber.shade50,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.star, color: Colors.amber),
                      title: Text(data['bankName'] ?? 'Unknown Bank', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${data['accountType'] ?? 'Type'}\n${currencyFormat.format(data['balance'] ?? 0)}'),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Account'),
                              content: const Text('Are you sure you want to delete this account?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await doc.reference.delete();
                          }
                        },
                      ),
                    ),
                  );
                }),
              ],
              // Other Banks Section
              if (otherBankDocs.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Other Banks',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: otherBankDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          title: Text(data['bankName'] ?? 'Unknown Bank'),
                          subtitle: Text('${data['accountType'] ?? 'Type'}\n${currencyFormat.format(data['balance'] ?? 0)}'),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.star_border, color: Colors.amber),
                                tooltip: 'Set as Default',
                                onPressed: () async {
                                  final batch = FirebaseFirestore.instance.batch();
                                  for (final d in docs) {
                                    batch.update(d.reference, {'isDefault': false});
                                  }
                                  batch.update(doc.reference, {'isDefault': true});
                                  await batch.commit();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Account'),
                                      content: const Text('Are you sure you want to delete this account?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await doc.reference.delete();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ] else
                const Expanded(child: SizedBox()), // To fill space if only default bank exists
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Account'),
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => _AddAccountDialog(accountsRef: accountsRef),
          );
        },
      ),
    );
  }
}

class _AddAccountDialog extends StatefulWidget {
  final CollectionReference accountsRef;
  const _AddAccountDialog({required this.accountsRef});

  @override
  State<_AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<_AddAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  String _bankName = 'CIMB';
  String _accountType = 'Savings';
  double _balance = 0;

  final List<String> _banks = [
    'CIMB',
    'Maybank',
    'Public Bank',
    'Hong Leong Bank',
    'RHB Bank',
    'Bank Islam',
    'BSN',
    'UOB',
    'HSBC'
  ];
  final List<String> _accountTypes = ['Savings', 'Current', 'Credit'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Linked Account'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Bank Name',
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                controller: TextEditingController(text: _bankName),
                onTap: () async {
                  final selected = await showDialog<String>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Select Bank'),
                      content: SizedBox(
                        width: double.maxFinite,
                        height: 300,
                        child: ListView(
                          children: _banks.map((bank) {
                            return RadioListTile<String>(
                              title: Text(bank),
                              value: bank,
                              groupValue: _bankName,
                              onChanged: (val) {
                                Navigator.pop(ctx, val);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                  if (selected != null) setState(() => _bankName = selected);
                },
              ),
              DropdownButtonFormField<String>(
                value: _accountType,
                decoration: const InputDecoration(labelText: 'Account Type'),
                items: _accountTypes
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _accountType = val);
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Balance'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter balance';
                  final val = double.tryParse(v);
                  if (val == null) return 'Enter a valid number';
                  return null;
                },
                onSaved: (v) => _balance = double.tryParse(v ?? '0') ?? 0,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              _formKey.currentState?.save();
              await widget.accountsRef.add({
                'bankName': _bankName,
                'accountType': _accountType,
                'balance': _balance,
                'isDefault': false,
              });
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}