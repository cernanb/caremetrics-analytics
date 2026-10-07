-- An encounter is completed no later than its appointment's checkout,
-- when the appointment was marked completed (the appointment's updated_at).
-- Returns the violating encounters; the test passes when no rows come back.
--
-- An encounter still in progress has no completed_at; a comparison with null is never true, so it is skipped.
-- Relying on updated_at is safe here: it only ever moves later, which can only make this rule easier to satisfy,
-- so a valid later edit to the appointment can never make this test fail.

select
    encounters.encounter_id,
    encounters.completed_at as encounter_completed_at,
    appointments.appointment_id,
    appointments.updated_at as appointment_checked_out_at

from {{ ref('stg_caremetrics__encounters') }} as encounters

inner join {{ ref('stg_caremetrics__appointments') }} as appointments
    on encounters.appointment_id = appointments.appointment_id

where encounters.completed_at > appointments.updated_at
