package com.smartlivestock.ranch.application.signal;

/**
 * NIX-430: published after an alert row is committed (both the application
 * service and the health ACL save paths). The push dispatch listener reloads
 * the alert itself, so the event stays minimal.
 */
public record AlertCreatedEvent(Long farmId, Long alertId) {
}
