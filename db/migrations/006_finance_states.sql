CREATE TABLE IF NOT EXISTS finance_states (
  user_id text PRIMARY KEY,
  revision bigint NOT NULL DEFAULT 1 CHECK (revision > 0),
  payload jsonb NOT NULL CHECK (payload->>'mode' = 'DEMO'),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS finance_states_updated_idx ON finance_states (updated_at DESC);
