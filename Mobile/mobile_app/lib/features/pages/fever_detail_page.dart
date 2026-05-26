import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/widgets/coming_soon_page.dart';

class FeverDetailPage extends StatelessWidget {
  const FeverDetailPage({super.key, required this.livestockId});
  final String livestockId;

  @override
  Widget build(BuildContext context) => const ComingSoonPage(title: '体温详情');
}
