-- Every completed appointment must have an encounter (the visit took place, so it was recorded).
-- Returns the violating appointments; the test passes when no rows come back.

select
    appointments.appointment_id,
    appointments.scheduled_at

from {{ ref('stg_caremetrics__appointments') }} as appointments
left join {{ ref('stg_caremetrics__encounters') }} as encounters
    on encounters.appointment_id = appointments.appointment_id

where appointments.appointment_status = 'completed'
    and encounters.encounter_id is null
