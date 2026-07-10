package com.smartlivestock.identity.application.dto;

public record AuthTokenDto(String accessToken, UserDto user) {
}
