import 'package:flutter/material.dart';

class B2bWorkerDetailPage extends StatelessWidget {
  const B2bWorkerDetailPage({super.key, required this.farmId});
  final String farmId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('牧工详情')),
      body: const Center(child: Text('TODO')),
    );
  }
}
