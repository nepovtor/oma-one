WITH migrated AS (
  SELECT COALESCE(jsonb_agg(
    CASE
      WHEN project->'proof' IS NULL OR project->'proof' = 'null'::jsonb THEN project
      ELSE jsonb_set(project, '{proof}', (project->'proof') || jsonb_build_object(
        'status', CASE
          WHEN project#>>'{proof,verified}' = 'expert' THEN 'EXPERT_VERIFIED'
          WHEN (project#>'{proof,object}' IS NOT NULL AND project#>'{proof,object}' <> 'null'::jsonb)
            OR (project#>'{proof,image}' IS NOT NULL AND project#>'{proof,image}' <> 'null'::jsonb) THEN 'EVIDENCE_SUBMITTED'
          ELSE 'SELF_REPORTED'
        END,
        'stepIds', COALESCE((
          SELECT jsonb_agg(step->>'id')
          FROM jsonb_array_elements(COALESCE(project#>'{plan,steps}', '[]'::jsonb)) AS step
        ), '[]'::jsonb),
        'photoHash', NULL,
        'digest', NULL,
        'inspectorId', NULL,
        'verifiedAt', NULL
      ))
    END
  ), '[]'::jsonb) AS projects
  FROM app_state, jsonb_array_elements(COALESCE(payload->'projects', '[]'::jsonb)) AS project
  WHERE singleton = true
)
UPDATE app_state
SET payload = jsonb_set(
  jsonb_set(payload, '{version}', '3'::jsonb),
  '{projects}', migrated.projects
)
FROM migrated
WHERE singleton = true;
