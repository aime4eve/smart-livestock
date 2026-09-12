import '../../l10n/gen/app_localizations.dart';
import '../models/core_models.dart';
import '../models/subscription_tier.dart';

/// Localized display labels for domain enums.
///
/// Follows the same extension pattern as [AppRouteL10n].
/// Arb keys follow the naming convention `{context}.{value}`,
/// e.g. `deviceStatus.online`, `livestockHealth.healthy`.

// ── DeviceStatus ────────────────────────────────────────────

extension DeviceStatusL10n on DeviceStatus {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case DeviceStatus.online:
        return l10n.deviceStatusOnline;
      case DeviceStatus.offline:
        return l10n.deviceStatusOffline;
    }
  }
}

// ── DeviceType ──────────────────────────────────────────────

extension DeviceTypeL10n on DeviceType {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case DeviceType.gps:
        return l10n.deviceTypeGps;
      case DeviceType.rumenCapsule:
        return l10n.deviceTypeRumenCapsule;
      case DeviceType.earTag:
        return l10n.deviceTypeEarTag;
    }
  }
}

// ── LivestockHealth ─────────────────────────────────────────

extension LivestockHealthL10n on LivestockHealth {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case LivestockHealth.healthy:
        return l10n.livestockHealthHealthy;
      case LivestockHealth.watch:
        return l10n.livestockHealthWatch;
      case LivestockHealth.abnormal:
        return l10n.livestockHealthAbnormal;
    }
  }
}

// ── Health status passthrough strings (backend enum .name()) ──
//
// These arrive from the API as plain strings (ActivityStatus / TempStatus /
// MotilityStatus `.name()`), so they can't be typed extensions like above.
// Unknown values fall back to the raw string instead of lying about them.

/// ActivityStatus: NORMAL / ELEVATED / LOW / ABNORMAL.
String activityStatusLabel(AppLocalizations l10n, String? value) =>
    switch (value) {
      'NORMAL' => l10n.activityStatusNormal,
      'ELEVATED' => l10n.activityStatusElevated,
      'LOW' => l10n.activityStatusLow,
      'ABNORMAL' => l10n.activityStatusAbnormal,
      _ => value ?? '--',
    };

/// TempStatus: NORMAL / ELEVATED / FEVER / CRITICAL.
String tempStatusLabel(AppLocalizations l10n, String? value) => switch (value) {
      'NORMAL' => l10n.tempStatusNormal,
      'ELEVATED' => l10n.tempStatusElevated,
      'FEVER' => l10n.tempStatusFever,
      'CRITICAL' => l10n.tempStatusCritical,
      _ => value ?? '--',
    };

/// MotilityStatus: NORMAL / LOW / ABNORMAL.
String motilityStatusLabel(AppLocalizations l10n, String? value) =>
    switch (value) {
      'NORMAL' => l10n.motilityStatusNormal,
      'LOW' => l10n.motilityStatusLow,
      'ABNORMAL' => l10n.motilityStatusAbnormal,
      _ => value ?? '--',
    };

// ── Breed ───────────────────────────────────────────────────

extension BreedL10n on Breed {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case Breed.angus:
        return l10n.livestockBreedAngus;
      case Breed.wagyu:
        return l10n.livestockBreedWagyu;
      case Breed.simmental:
        return l10n.livestockBreedSimmental;
      case Breed.limousin:
        return l10n.livestockBreedLimousin;
      case Breed.other:
        return l10n.livestockBreedOther;
    }
  }
}

// ── SubscriptionTier ────────────────────────────────────────

extension SubscriptionTierL10n on SubscriptionTier {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case SubscriptionTier.basic:
        return l10n.subscriptionTierBasic;
      case SubscriptionTier.standard:
        return l10n.subscriptionTierStandard;
      case SubscriptionTier.premium:
        return l10n.subscriptionTierPremium;
      case SubscriptionTier.enterprise:
        return l10n.subscriptionTierEnterprise;
    }
  }
}
