import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final String uid;
  const TransactionHistoryScreen({super.key, required this.uid});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String selectedBank = 'All Banks';
  String selectedCategory = 'All';
  List<Map<String, dynamic>> bankOptions = [];
  List<Map<String, dynamic>> allTransactions = [];
  bool isLoading = true;

  final List<String> categories = [
    'All', 'Groceries', 'Food & Drink', 'Bills', 'Transport', 'Others'
  ];

  @override
  void initState() {
    super.initState();
    _fetchBanksAndTransactions();
  }

  Future<void> _fetchBanksAndTransactions() async {
    setState(() => isLoading = true);
    final banksSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('linkedAccounts')
        .get();

    bankOptions = banksSnap.docs.map((doc) {
      final data = doc.data();
      print('Bank doc: ${doc.id}, bankName: ${data['bankName']}, accountType: ${data['accountType']}');
      return {
        'id': doc.id,
        'label': '${data['bankName'] ?? doc.id} – ${data['accountType'] ?? ''}',
      };
    }).toList();
    print('Fetched ${banksSnap.docs.length} banks');

    // Fetch all transactions from all banks
    List<Map<String, dynamic>> txs = [];
    for (var bank in banksSnap.docs) {
      final txSnap = await bank.reference.collection('transactions').get();
      print('Bank ${bank.id} has ${txSnap.docs.length} transactions');
      txs.addAll(txSnap.docs.map((txDoc) {
        final txData = txDoc.data();
        print('Transaction data: $txData');
        txData['bankId'] = bank.id;
        return txData;
      }));
    }
    txs.sort((a, b) => (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));
    setState(() {
      allTransactions = txs;
      isLoading = false;
    });
  }

  List<Map<String, dynamic>> get filteredTransactions {
    var txs = allTransactions;
    if (selectedBank != 'All Banks') {
      txs = txs.where((tx) => tx['bankId'] == selectedBank).toList();
    }
    if (selectedCategory != 'All') {
      txs = txs.where((tx) => (tx['category'] ?? 'Others') == selectedCategory).toList();
    }
    return txs;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_MY', symbol: 'RM');
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButton<String>(
                    value: selectedBank,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: 'All Banks',
                        child: Text('All Banks'),
                      ),
                      ...bankOptions.map((bank) => DropdownMenuItem(
                            value: bank['id'],
                            child: Text(bank['label']),
                          )),
                    ],
                    onChanged: (val) {
                      setState(() => selectedBank = val ?? 'All Banks');
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    items: categories
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() => selectedCategory = val ?? 'All');
                    },
                  ),
                ),
                const Divider(),
                Expanded(
                  child: filteredTransactions.isEmpty
                      ? const Center(child: Text('No transactions found.'))
                      : ListView.builder(
                          itemCount: filteredTransactions.length,
                          itemBuilder: (context, idx) {
                            final tx = filteredTransactions[idx];
                            final dt = (tx['timestamp'] as Timestamp).toDate();
                            final amountRaw = tx['amount'];
                            final amount = amountRaw is num
                                ? amountRaw.toDouble()
                                : double.tryParse(amountRaw.toString()) ?? 0.0;
                            return ListTile(
                              title: Text(tx['merchant'] ?? 'Unknown'),
                              subtitle: Text(currencyFormat.format(amount)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(DateFormat('dd MMM yyyy, hh:mm a').format(dt)),
                                  if (tx['category'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Chip(
                                        label: Text(tx['category']),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
