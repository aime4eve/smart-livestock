import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/widgets/coming_soon_page.dart';

class TenantEditPage extends StatelessWidget {
  const TenantEditPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) => const ComingSoonPage(title: '编辑租户');
}
