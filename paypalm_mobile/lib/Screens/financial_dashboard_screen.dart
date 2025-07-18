import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

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

          final List<String> categories = [
            'Groceries', 'Food & Drink', 'Bills', 'Transport', 'Others'
          ];

          final List<Color> pieColors = [
            Colors.indigo,
            Colors.orange,
            Colors.green,
            Colors.red,
            Colors.purple,
          ];

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
              }

              final currencyFormat = NumberFormat.currency(symbol: "RM ");

              final pieSections = categoryTotals.entries.map((entry) {
                final percent = totalSpent == 0 ? 0 : entry.value / totalSpent * 100;
                final idx = categories.indexOf(entry.key);
                return PieChartSectionData(
                  value: entry.value,
                  title: percent > 0 ? '${percent.toStringAsFixed(1)}%' : '',
                  color: pieColors[idx >= 0 ? idx : pieColors.length - 1],
                  radius: 75, // Slightly larger for visibility
                  titleStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // White for contrast
                    shadows: [
                      Shadow(blurRadius: 4, color: Colors.black.withOpacity(0.5)),
                    ],
                  ),
                );
              }).toList();

              // Responsive frame using LayoutBuilder
              return LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = constraints.maxWidth < 500
                      ? constraints.maxWidth
                      : 500.0;
                  final cardHeight = constraints.maxHeight < 700
                      ? constraints.maxHeight * 0.95
                      : 700.0; // Make the frame longer

                  return Center(
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      color: Colors.white,
                      child: Container(
                        width: cardWidth,
                        height: cardHeight,
                        padding: const EdgeInsets.all(24.0),
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
                              height: 260, // Taller pie chart for visibility
                              child: PieChart(
                                PieChartData(
                                  sections: pieSections,
                                  centerSpaceRadius: 40,
                                  sectionsSpace: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            ...categoryTotals.entries.map((entry) {
                              final idx = categoryTotals.keys.toList().indexOf(entry.key);
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: pieColors[idx % pieColors.length],
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.black12, width: 1),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      currencyFormat.format(entry.value),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: Colors.indigo,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}