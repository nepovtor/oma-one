CREATE TABLE IF NOT EXISTS oidc_login_attempts (
  state_hash text PRIMARY KEY,
  code_verifier text NOT NULL,
  nonce text NOT NULL,
  return_to text NOT NULL DEFAULT '/',
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL
);

CREATE INDEX IF NOT EXISTS oidc_login_attempts_expires_at_idx ON oidc_login_attempts (expires_at);

CREATE TABLE IF NOT EXISTS oidc_identities (
  issuer text NOT NULL,
  subject text NOT NULL,
  user_id text NOT NULL,
  email text,
  created_at timestamptz NOT NULL DEFAULT now(),
  last_login_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (issuer, subject)
);

CREATE INDEX IF NOT EXISTS oidc_identities_user_id_idx ON oidc_identities (user_id);
