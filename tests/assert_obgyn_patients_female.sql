{{ config(severity='warn') }}

-- An OB/GYN patient should be female.
-- The source doesn't enforce it.
-- Warns rather than fails: some patients have a recorded gender of other or unknown,
-- and an OB/GYN visit is clinically possible for them.
-- Returns the violating appointments; the test passes when no rows come back.

select
    appointments.appointment_id,
    patients.patient_id,
    providers.provider_id,
    patients.gender

from {{ ref('stg_caremetrics__appointments') }} as appointments

inner join {{ ref('stg_caremetrics__patients') }} as patients
    on appointments.patient_id = patients.patient_id
inner join {{ ref('stg_caremetrics__providers') }} as providers
    on appointments.provider_id = providers.provider_id

where
    providers.specialty = 'Obstetrics and Gynecology'
    and patients.gender != 'female'
