select 
    id as payer_id,
    name as payer_name,
    payer_type,
    created_at,
    updated_at

from {{ source('caremetrics', 'payers') }}
