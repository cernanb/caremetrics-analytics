-- An encounter starts within 60 minutes of its appointment's scheduled time, early or late,
-- and never before the appointment was booked.
-- Returns the violating encounters; the test passes when no rows come back.

select
    encounters.encounter_id,
    appointments.appointment_id,
    appointments.created_at as appointment_booked_at,
    appointments.scheduled_at,
    encounters.started_at,
    -- Signed: negative means the visit started early, positive means late.
    timestamp_diff(encounters.started_at, appointments.scheduled_at, minute) as minutes_from_scheduled

from {{ ref('stg_caremetrics__encounters') }} as encounters

inner join {{ ref('stg_caremetrics__appointments') }} as appointments
    on appointments.appointment_id = encounters.appointment_id

where abs(timestamp_diff(encounters.started_at, appointments.scheduled_at, minute)) > 60
    or encounters.started_at < appointments.created_at
