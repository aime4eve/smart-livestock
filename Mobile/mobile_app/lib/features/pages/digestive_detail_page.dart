import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/widgets/coming_soon_page.dart';

class DigestiveDetailPage extends StatelessWidget {
  const DigestiveDetailPage({super.key, required this.livestockId});
  final String livestockId;

  @override
  Widget build(BuildContext context) => const ComingSoonPage(title: '消化详情');
}
