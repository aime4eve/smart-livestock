-- Fix seed subscription trial period from 30 days to 14 days.
-- Design spec and SubscriptionApplicationService.getOrCreateSubscription() both use 14 days.

UPDATE subscriptions
SET trial_ends_at = started_at + INTERVAL '14 days'
WHERE status = 'trial'
  AND trial_ends_at = started_at + INTERVAL '30 days';
