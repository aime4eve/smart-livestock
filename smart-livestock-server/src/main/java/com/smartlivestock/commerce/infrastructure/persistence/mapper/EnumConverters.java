package com.smartlivestock.commerce.infrastructure.persistence.mapper;

public final class EnumConverters {

    private EnumConverters() {}

    public static String toDb(Enum<?> value) {
        return value.name().toLowerCase();
    }

    public static <T extends Enum<T>> T fromDb(String dbValue, Class<T> enumClass) {
        return Enum.valueOf(enumClass, dbValue.toUpperCase());
    }
}
