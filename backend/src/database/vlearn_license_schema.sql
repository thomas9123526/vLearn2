-- vLearnLicense database schema
-- Run once against a dedicated database (separate from the main app DB):
--
--   createdb vLearnLicense
--   psql -d vLearnLicense -f vlearn_license_schema.sql
--
-- Connection string goes in the backend .env as:
--   LICENSE_DB_URL=postgresql://user:pass@localhost:5432/vLearnLicense
-- The KeyGenerator also connects to this DB for generate_log inserts.

-- ── generate_log ─────────────────────────────────────────────────────────────
-- One row per license cert issued by KeyGenerator.
-- The cert_der column lets the backend reconstruct the full cert from
-- history if needed (e.g. to re-verify a serial without the client re-sending).

CREATE TABLE IF NOT EXISTS generate_log (
  id            BIGSERIAL    PRIMARY KEY,
  serial        TEXT         UNIQUE NOT NULL,
  machine_id    TEXT         NOT NULL,
  user_name     TEXT,
  mode          TEXT         NOT NULL CHECK (mode IN ('period', 'permanent')),
  days          INT          NOT NULL,
  not_before    TIMESTAMPTZ  NOT NULL,
  not_after     TIMESTAMPTZ  NOT NULL,
  operator      TEXT         NOT NULL,
  cert_der      BYTEA        NOT NULL,
  generated_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_generate_log_machine_id ON generate_log (machine_id);
CREATE INDEX IF NOT EXISTS idx_generate_log_not_after  ON generate_log (not_after);

-- ── verify_log ────────────────────────────────────────────────────────────────
-- One row per POST /license/verify call.
-- result values: 'valid' | 'expired' | 'mismatch' | 'forged' | 'invalid'

CREATE TABLE IF NOT EXISTS verify_log (
  id           BIGSERIAL    PRIMARY KEY,
  serial       TEXT         NOT NULL,
  machine_id   TEXT         NOT NULL,
  user_id      UUID,
  result       TEXT         NOT NULL
                            CHECK (result IN ('valid','expired','mismatch','forged','invalid')),
  verified_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
  CONSTRAINT fk_verify_serial
    FOREIGN KEY (serial) REFERENCES generate_log (serial)
    ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_verify_log_serial     ON verify_log (serial);
CREATE INDEX IF NOT EXISTS idx_verify_log_machine_id ON verify_log (machine_id);
CREATE INDEX IF NOT EXISTS idx_verify_log_user_id    ON verify_log (user_id)
  WHERE user_id IS NOT NULL;
