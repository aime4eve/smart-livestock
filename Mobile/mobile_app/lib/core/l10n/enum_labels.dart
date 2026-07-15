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
