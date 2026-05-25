import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/widgets/coming_soon_page.dart';

class TenantDetailPage extends StatelessWidget {
  const TenantDetailPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) => const ComingSoonPage(title: '租户详情');
}
