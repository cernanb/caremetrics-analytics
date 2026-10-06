-- The parties of the encounter need to match the parties of the appointment
-- Returns the violating encounters; the test passes when no rows come back.

select
    encounters.encounter_id,
    encounters.patient_id as encounter_patient_id,
    appointments.patient_id as appointment_patient_id,
    encounters.provider_id as encounter_provider_id,
    appointments.provider_id as appointment_provider_id,
    encounters.location_id as encounter_location_id,
    appointments.location_id as appointment_location_id,

from {{ ref('stg_caremetrics__encounters') }} as encounters
inner join {{ ref('stg_caremetrics__appointments') }} as appointments
    on encounters.appointment_id = appointments.appointment_id

where appointments.patient_id != encounters.patient_id
    or appointments.provider_id != encounters.provider_id
    or appointments.location_id != encounters.location_id
