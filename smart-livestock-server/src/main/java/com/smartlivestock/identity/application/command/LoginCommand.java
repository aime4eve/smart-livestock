package com.smartlivestock.identity.application.command;

/**
 * @param identifier account / E.164 phone / email — classified server-side
 * @param password   account password
 */
public record LoginCommand(String identifier, String password) {
}
