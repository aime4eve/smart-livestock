import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/features/epidemic/presentation/widgets/epidemic_upsell_sheet.dart';
import 'package:hkt_livestock_agentic/features/epidemic/presentation/widgets/mark_diseased_sheet.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/subscription_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Role gate for the alert-entry "mark as source" action (spec §5.4): marking
/// is a management action, so only OWNER / B2B_ADMIN render the trigger —
/// the same policy as the detail page's MarkDiseasedEntryRow.
bool isEpidemicManagerRole(UserRole? role) =>
    role == UserRole.owner || role == UserRole.b2bAdmin;

/// Subscription + sheet fork shared by every "mark as source" trigger on
/// EPIDEMIC alerts (spec §5.2 entry ③, prototype P5): subscribed managers
/// get the prefilled [MarkDiseasedSheet] (subtitle tagged "from alert"),
/// free-tier managers get the P6 upsell sheet instead of the real flow.
///
/// Hosts call this from a page-level context after popping any detail sheet,
/// so the mark sheet never stacks on top of another modal.
Future<void> showMarkDiseasedFromAlarm(
  BuildContext context,
  WidgetRef ref, {
  required String livestockId,
  required String livestockCode,
}) {
  final tier =
      ref.read(subscriptionControllerProvider).value?.tier ??
      SubscriptionTier.basic;
  if (!checkTierAccess(tier, FeatureFlags.epidemicAlert)) {
    return EpidemicUpsellSheet.show(context);
  }
  final l10n = AppLocalizations.of(context)!;
  return MarkDiseasedSheet.show(
    context,
    livestockId: livestockId,
    livestockCode: livestockCode,
    subtitle: l10n.markDiseasedFromAlarm,
  );
}
