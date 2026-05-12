package com.smartlivestock.ranch.application.command;

public record AcknowledgeAlertCommand(Long alertId, Long userId) {
}
