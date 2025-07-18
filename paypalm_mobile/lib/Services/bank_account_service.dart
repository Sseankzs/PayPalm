import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const List<String> bankList = [
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

const List<String> accountTypeList = [
  'Savings',
  'Current',
  'Credit'
];

Future<void> showAddBankAccountDialog(BuildContext context, CollectionReference accountsRef) async {
  final formKey = GlobalKey<FormState>();
  String bankName = bankList.first;
  String accountType = accountTypeList.first;
  double balance = 0;

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Add Linked Account'),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) => TextFormField(
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Bank Name',
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  controller: TextEditingController(text: bankName),
                  onTap: () async {
                    final selected = await showDialog<String>(
                      context: context,
                      builder: (ctx2) => AlertDialog(
                        title: const Text('Select Bank'),
                        content: SizedBox(
                          width: double.maxFinite,
                          height: 300,
                          child: ListView(
                            children: bankList.map((bank) {
                              return RadioListTile<String>(
                                title: Text(bank),
                                value: bank,
                                groupValue: bankName,
                                onChanged: (val) {
                                  Navigator.pop(ctx2, val);
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                    if (selected != null) setState(() => bankName = selected);
                  },
                ),
              ),
              StatefulBuilder(
                builder: (context, setState) => DropdownButtonFormField<String>(
                  value: accountType,
                  decoration: const InputDecoration(labelText: 'Account Type'),
                  items: accountTypeList
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => accountType = val);
                  },
                ),
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
                onSaved: (v) => balance = double.tryParse(v ?? '0') ?? 0,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (formKey.currentState?.validate() ?? false) {
              formKey.currentState?.save();
              final docId =
                  '${bankName.trim().toLowerCase().replaceAll(' ', '')}_${accountType.trim().toLowerCase().replaceAll(' ', '')}';
              final docRef = accountsRef.doc(docId);

              final existing = await docRef.get();
              if (existing.exists) {
                await showDialog(
                  context: context,
                  builder: (ctx2) => AlertDialog(
                    title: const Text('Account Already Linked'),
                    content: Text("You've already linked a $accountType account with $bankName."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx2),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
                return;
              }

              await docRef.set({
                'bankName': bankName,
                'accountType': accountType,
                'balance': balance,
                'isDefault': false,
                'createdAt': FieldValue.serverTimestamp(),
              });

              Navigator.pop(ctx);
            }
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}