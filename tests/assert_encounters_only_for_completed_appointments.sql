-- An encounter records a visit that took place, so its appointment must be completed.
-- Returns the violating encounters; the test passes when no rows come back.

select
    encounters.encounter_id,
    encounters.appointment_id,
    appointments.appointment_status

from {{ ref('stg_caremetrics__encounters') }} as encounters
inner join {{ ref('stg_caremetrics__appointments') }} as appointments
    on encounters.appointment_id = appointments.appointment_id

where appointments.appointment_status != 'completed'
