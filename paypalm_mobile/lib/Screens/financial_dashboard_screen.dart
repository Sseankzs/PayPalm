import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  final String uid;
  const DashboardScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    dev.log('Current UID: $uid');

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    final banksRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('linkedAccounts');

    dev.log('Querying banksRef: users/$uid/linkedAccounts');

    return Scaffold(
      appBar: AppBar(title: const Text('Spending Dashboard')),
      body: StreamBuilder<QuerySnapshot>(
        stream: banksRef.snapshots(),
        builder: (context, bankSnapshot) {
          dev.log('Bank snapshot state: ${bankSnapshot.connectionState}');
          if (bankSnapshot.connectionState == ConnectionState.waiting) {
            dev.log('Waiting for bank accounts...');
            return const Center(child: CircularProgressIndicator());
          }
          if (!bankSnapshot.hasData || bankSnapshot.data!.docs.isEmpty) {
            dev.log('No linked bank accounts found!');
            return const Center(child: Text('No linked bank accounts.'));
          }

          final bankDocs = bankSnapshot.data!.docs;
          dev.log('Fetched ${bankDocs.length} bank accounts: ${bankDocs.map((d) => d.id).toList()}');

          // Fetch all transactions from all banks
          return FutureBuilder<List<QuerySnapshot>>(
            future: Future.wait(bankDocs.map((bankDoc) {
              dev.log('Querying transactions for bank: ${bankDoc.id}');
              return bankDoc.reference
                  .collection('transactions')
                  .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
                  .orderBy('timestamp', descending: true)
                  .get();
            })),
            builder: (context, txSnapshot) {
              dev.log('Transaction snapshot state: ${txSnapshot.connectionState}');
              if (txSnapshot.connectionState == ConnectionState.waiting) {
                dev.log('Waiting for transactions...');
                return const Center(child: CircularProgressIndicator());
              }
              if (!txSnapshot.hasData || txSnapshot.data!.isEmpty) {
                dev.log('No transactions found for this month!');
                return const Center(child: Text('No transactions this month.'));
              }

              // Merge all transactions
              final docs = txSnapshot.data!.expand((qs) => qs.docs).toList();
              dev.log('Fetched ${docs.length} transactions.');

              double totalSpent = 0;
              final Map<String, double> categoryTotals = {};
              final List<Map<String, dynamic>> recentTransactions = [];

              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                dev.log('Transaction: $data');
                final amountRaw = data['amount'];
                final amount = amountRaw is num
                    ? amountRaw.toDouble()
                    : double.tryParse(amountRaw.toString()) ?? 0.0;
                final category = data['category'] ?? 'Others';
                totalSpent += amount;
                categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
                if (recentTransactions.length < 3) {
                  recentTransactions.add(data);
                }
              }

              final currencyFormat = NumberFormat.currency(symbol: "RM ");

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Spent This Month',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      currencyFormat.format(totalSpent),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    Text('Spending by Category', style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(
                      height: 120,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: categoryTotals.entries.map((entry) {
                          final percent = totalSpent == 0 ? 0 : entry.value / totalSpent;
                          return Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: (80 * percent).toDouble(),
                                  width: 24,
                                  color: Colors.indigo,
                                ),
                                const SizedBox(height: 4),
                                Text(entry.key, style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Recent Transactions', style: Theme.of(context).textTheme.titleMedium),
                    ...recentTransactions.map((tx) {
                      final dt = (tx['timestamp'] as Timestamp).toDate();
                      final amountRaw = tx['amount'];
                      final amount = amountRaw is num
                          ? amountRaw.toDouble()
                          : double.tryParse(amountRaw.toString()) ?? 0.0;
                      return ListTile(
                        title: Text(tx['merchant'] ?? 'Unknown'),
                        subtitle: Text(DateFormat.yMMMd().add_jm().format(dt)),
                        trailing: Text(currencyFormat.format(amount)), 
                      );
                    }),
                    const Spacer(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}