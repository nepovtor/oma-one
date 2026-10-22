CREATE TABLE IF NOT EXISTS product_events (
  id bigserial PRIMARY KEY,
  user_id text,
  event_name text NOT NULL,
  properties jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS product_events_name_created_idx ON product_events (event_name, created_at DESC);
CREATE INDEX IF NOT EXISTS product_events_created_idx ON product_events (created_at DESC);
