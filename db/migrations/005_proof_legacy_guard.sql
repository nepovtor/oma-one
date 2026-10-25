-- Corrective migration for installations that already ran 004_proof_statuses.sql.
-- A legacy "expert" flag or a stored image alone MUST NOT grant a proof status.
-- Genuine new-format records are preserved only when the plan, photo evidence
-- and (where applicable) named/time-stamped expert review are present.
WITH entries AS (
 SELECT item.project,item.ordinality,
   CASE WHEN jsonb_typeof(item.project#>'{plan,steps}')='array'
     THEN item.project#>'{plan,steps}' ELSE '[]'::jsonb END AS plan_steps,
   CASE WHEN jsonb_typeof(item.project#>'{proof,checklist}')='array'
     THEN item.project#>'{proof,checklist}' ELSE '[]'::jsonb END AS checklist,
   CASE WHEN jsonb_typeof(item.project#>'{proof,stepIds}')='array'
     THEN item.project#>'{proof,stepIds}' ELSE '[]'::jsonb END AS step_ids
 FROM app_state AS a
 CROSS JOIN LATERAL jsonb_array_elements(
   CASE WHEN jsonb_typeof(a.payload->'projects')='array'
     THEN a.payload->'projects' ELSE '[]'::jsonb END
 ) WITH ORDINALITY AS item(project,ordinality)
 WHERE a.singleton=true
),
evidence AS (
 SELECT *,
   (
     jsonb_array_length(plan_steps)>0
     AND jsonb_array_length(checklist)=jsonb_array_length(plan_steps)
     AND checklist=(SELECT jsonb_agg('true'::jsonb) FROM jsonb_array_elements(plan_steps))
     AND step_ids=(SELECT jsonb_agg(step.value->'id' ORDER BY step.position)
       FROM jsonb_array_elements(plan_steps) WITH ORDINALITY AS step(value,position))
     AND jsonb_typeof(project#>'{proof,object}')='object'
     AND COALESCE(project#>>'{proof,object,key}','')<>''
     AND COALESCE(project#>>'{proof,photoHash}','') ~* '^[0-9a-f]{64}$'
     AND COALESCE(project#>>'{proof,digest}','') ~* '^[0-9a-f]{64}$'
   ) AS has_evidence
 FROM entries
),
decisions AS (
 SELECT project,ordinality,
   CASE
     WHEN project#>>'{proof,status}'='EXPERT_VERIFIED'
       AND has_evidence
       AND COALESCE(project#>>'{proof,inspectorId}','')<>''
       AND COALESCE(project#>>'{proof,verifiedAt}','')<>''
     THEN 'EXPERT_VERIFIED'
     WHEN project#>>'{proof,status}' IN ('EVIDENCE_SUBMITTED','EXPERT_VERIFIED')
       AND has_evidence
     THEN 'EVIDENCE_SUBMITTED'
     WHEN project#>>'{proof,status}'='IN_PROGRESS' THEN 'IN_PROGRESS'
     ELSE 'SELF_REPORTED'
   END AS next_status
 FROM evidence
),
rewritten AS (
 SELECT COALESCE(jsonb_agg(
   CASE WHEN jsonb_typeof(project->'proof')<>'object' THEN project
   ELSE jsonb_set(project,'{proof}',(project->'proof') || jsonb_build_object(
     'status',next_status,
     'verified',CASE WHEN next_status='EXPERT_VERIFIED' THEN 'expert' ELSE 'self' END,
     'inspectorId',CASE WHEN next_status='EXPERT_VERIFIED'
       THEN project#>>'{proof,inspectorId}' ELSE NULL END,
     'verifiedAt',CASE WHEN next_status='EXPERT_VERIFIED'
       THEN project#>>'{proof,verifiedAt}' ELSE NULL END
   )) END ORDER BY ordinality
 ),'[]'::jsonb) AS projects
 FROM decisions
)
UPDATE app_state AS a
SET payload=jsonb_set(a.payload,'{projects}',rewritten.projects)
FROM rewritten
WHERE a.singleton=true;
