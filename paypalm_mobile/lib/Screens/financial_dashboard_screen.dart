import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    final transactionsQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Spending Dashboard')),
      body: StreamBuilder<QuerySnapshot>(
        stream: transactionsQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No transactions this month.'));
          }

          final docs = snapshot.data!.docs;
          double totalSpent = 0;
          final Map<String, double> categoryTotals = {};
          final List<Map<String, dynamic>> recentTransactions = [];

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final amount = (data['amount'] ?? 0).toDouble();
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
                  return ListTile(
                    title: Text(tx['merchant'] ?? 'Unknown'),
                    subtitle: Text(DateFormat.yMMMd().add_jm().format(dt)),
                    trailing: Text(currencyFormat.format(tx['amount'] ?? 0)),
                  );
                }),
                const Spacer(),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/transactions'),
                    child: const Text('See All Transactions'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}