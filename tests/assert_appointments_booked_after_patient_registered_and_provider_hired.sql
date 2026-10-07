-- An appointment should be booked (created_at) after its patient registered (created_at)
-- and after its provider was hired (created_at).
-- Returns violating appointments; the test passes when no rows come back.

select
    appointments.appointment_id,
    appointments.created_at as appointment_booked_at,
    patients.created_at as patient_registered_at,
    providers.created_at as provider_hired_at

from {{ ref('stg_caremetrics__appointments') }} as appointments

inner join {{ ref('stg_caremetrics__patients') }} as patients
    on appointments.patient_id = patients.patient_id
inner join {{ ref('stg_caremetrics__providers') }} as providers
    on appointments.provider_id = providers.provider_id

where
    appointments.created_at < patients.created_at
    or appointments.created_at < providers.created_at
