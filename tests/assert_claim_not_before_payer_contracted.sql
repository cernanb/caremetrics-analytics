-- A claim cannot be created before its payer was contracted (the payer's created_at date).
-- Returns the violating claims; the test passes when no rows come back.

select
    claims.claim_id,
    payers.payer_id,
    claims.created_at as claim_created_at,
    payers.created_at as payer_contracted_at

from {{ ref('stg_caremetrics__claims') }} as claims
inner join {{ ref('stg_caremetrics__payers') }} as payers
    on claims.payer_id = payers.payer_id

where claims.created_at < payers.created_at