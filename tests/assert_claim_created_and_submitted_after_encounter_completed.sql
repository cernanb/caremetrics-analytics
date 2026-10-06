-- A claim is created only after its encounter completed (charges are captured after the visit),
-- and submitted to the payer only after that too.
-- Returns the violating claims; the test passes when no rows come back.
--
-- Null timestamps are skipped on purpose: a pending claim has no submitted_at yet,
-- and a comparison with null is never true, so there is nothing to check until it is submitted.

select
    claims.claim_id,
    claims.encounter_id,
    encounters.completed_at as encounter_completed_at,
    claims.created_at as claim_created_at,
    claims.submitted_at as claim_submitted_at

from {{ ref('stg_caremetrics__claims') }} as claims
inner join {{ ref('stg_caremetrics__encounters') }} as encounters
    on claims.encounter_id = encounters.encounter_id

where claims.created_at < encounters.completed_at
    or claims.submitted_at < encounters.completed_at
