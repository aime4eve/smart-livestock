-- Audit log table — domain event write side
CREATE TABLE audit_logs (
    id              BIGSERIAL PRIMARY KEY,
    event_id        VARCHAR(36)  NOT NULL,
    event_type      VARCHAR(100) NOT NULL,
    tenant_id       BIGINT,
    user_id         BIGINT,
    action          VARCHAR(50)  NOT NULL,
    details         JSONB,
    occurred_at     TIMESTAMPTZ  NOT NULL,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_logs_tenant_id ON audit_logs (tenant_id);
CREATE INDEX idx_audit_logs_user_id   ON audit_logs (user_id);
CREATE INDEX idx_audit_logs_action    ON audit_logs (action);
CREATE INDEX idx_audit_logs_occurred  ON audit_logs (occurred_at);
