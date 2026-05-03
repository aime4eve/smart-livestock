import 'package:flutter/material.dart';

class B2bRevenueDetailPage extends StatelessWidget {
  const B2bRevenueDetailPage({super.key, required this.periodId});
  final String periodId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('对账详情')),
      body: const Center(child: Text('TODO')),
    );
  }
}
