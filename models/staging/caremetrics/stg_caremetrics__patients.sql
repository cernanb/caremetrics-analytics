select
    id as patient_id,
    first_name,
    last_name,
    date_of_birth,
    gender,
    state,
    created_at,
    updated_at

from {{ source('caremetrics', 'patients') }}
