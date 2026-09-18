import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_card.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Static help & support page: quick links, FAQ and contact guidance.
/// Reachable only via push from the mine page, so the AppBar back button
/// pops back to it.
class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final faqs = <(String, String)>[
      (l10n.helpSupportFaqBindQ, l10n.helpSupportFaqBindA),
      (l10n.helpSupportFaqOfflineQ, l10n.helpSupportFaqOfflineA),
      (l10n.helpSupportFaqAlertQ, l10n.helpSupportFaqAlertA),
      (l10n.helpSupportFaqDataQ, l10n.helpSupportFaqDataA),
      (l10n.helpSupportFaqHealthQ, l10n.helpSupportFaqHealthA),
    ];
    final guides = <(String, String)>[
      (l10n.helpSupportGuideBindTitle, l10n.helpSupportGuideBindSteps),
      (l10n.helpSupportGuideOfflineTitle, l10n.helpSupportGuideOfflineSteps),
      (l10n.helpSupportGuideAlertTitle, l10n.helpSupportGuideAlertSteps),
      (l10n.helpSupportGuideHealthTitle, l10n.helpSupportGuideHealthSteps),
    ];
    final guideTiles = <Widget>[];
    for (final (i, (title, steps)) in guides.indexed) {
      if (i > 0) guideTiles.add(const Divider(height: 1, indent: 16, endIndent: 16));
      guideTiles.add(ExpansionTile(
        key: Key('help-support-guide-$i'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Text(title, style: Theme.of(context).textTheme.titleSmall),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (n, step) in steps.split('\n').indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('${n + 1}. $step',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
              ],
            ),
          ),
        ],
      ));
    }

    return Scaffold(
      key: const Key('page-help-support'),
      appBar: AppBar(title: Text(l10n.mineHelpSupportTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.helpSupportGuideTitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          HighfiCard(
            child: Column(children: guideTiles),
          ),
          const SizedBox(height: 16),
          Text(l10n.helpSupportFaqTitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          HighfiCard(
            child: Column(
              children: [
                for (final (i, entry) in faqs.indexed) ...[
                  if (i > 0)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                  ExpansionTile(
                    key: Key('help-support-faq-$i'),
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                    childrenPadding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    title: Text(entry.$1,
                        style: Theme.of(context).textTheme.titleSmall),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(entry.$2,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.helpSupportContactTitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          HighfiCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.support_agent),
              title: Text(l10n.helpSupportContactTitle),
              subtitle: Text(l10n.helpSupportContactDesc),
              isThreeLine: true,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
