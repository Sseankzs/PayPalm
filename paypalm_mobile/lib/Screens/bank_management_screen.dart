import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../Services/bank_account_service.dart';

class BankManagementScreen extends StatelessWidget {
  final String uid;
  const BankManagementScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
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

          // Sort otherBankDocs by balance descending before displaying
          final otherBankDocsSorted = List.from(otherBankDocs)
            ..sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aBalance = (aData['balance'] ?? 0).toDouble();
              final bBalance = (bData['balance'] ?? 0).toDouble();
              return bBalance.compareTo(aBalance);
            });

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
                    children: otherBankDocsSorted.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: _getBankIcon(data['bankName'] ?? ''),
                          title: Text(data['bankName'] ?? 'Unknown Bank', style: const TextStyle(fontWeight: FontWeight.bold)),
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
          showAddBankAccountDialog(context, accountsRef);
        },
      ),
    );
  }

  Widget _getBankIcon(String bankName) {
    switch (bankName) {
      case 'Maybank':
        return Image.asset('assets/banks/maybank.png', width: 32, height: 32); // Add maybank.png to assets
      case 'CIMB':
        return Image.asset('assets/banks/cimb.png', width: 32, height: 32);
      case 'Public Bank':
        return Image.asset('assets/banks/publicbank.png', width: 32, height: 32);
      case 'RHB':
        return Image.asset('assets/banks/rhb.png', width: 32, height: 32);
      case 'Hong Leong':
        return Image.asset('assets/banks/hongleong.png', width: 32, height: 32);
      case 'Ambank':
        return Image.asset('assets/banks/ambank.png', width: 32, height: 32);
      case 'Bank Islam':
        return Image.asset('assets/banks/bankislam.png', width: 32, height: 32);
      case 'UOB':
        return Image.asset('assets/banks/uob.png', width: 32, height: 32);
      case 'HSBC':
        return Image.asset('assets/banks/hsbc.png', width: 32, height: 32);
      case 'OCBC':
        return Image.asset('assets/banks/ocbc.png', width: 32, height: 32);
      default:
        return const Icon(Icons.account_balance_wallet, color: Colors.grey, size: 32);
    }
  }
}