package com.smartlivestock.shared.domain;

import java.util.Objects;

public abstract class Entity {
    private Long id;

    public Long getId() { return id; }
    void setId(Long id) { this.id = id; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Entity that = (Entity) o;
        return id != null && id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
}
