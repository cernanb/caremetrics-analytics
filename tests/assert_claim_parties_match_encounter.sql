-- A claim's patient and provider must match its encounter's.
-- The source enforces this with a composite foreign key; BigQuery does not.
-- Returns the violating claims; the test passes when no rows come back.

select
    claims.claim_id,
    claims.patient_id as claim_patient_id,
    encounters.patient_id as encounter_patient_id,
    claims.provider_id as claim_provider_id,
    encounters.provider_id as encounter_provider_id

from {{ ref('stg_caremetrics__claims') }} as claims
inner join {{ ref('stg_caremetrics__encounters') }} as encounters
    on claims.encounter_id = encounters.encounter_id

where claims.patient_id != encounters.patient_id
    or claims.provider_id != encounters.provider_id
