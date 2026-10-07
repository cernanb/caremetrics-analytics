-- Appointments cannot be scheduled (scheduled_at) or booked (created_at)
-- before the clinic's (location) go-live date (created_at).
-- Returns the violating appointments; the test passes when no rows come back.

select
    appointments.appointment_id,
    appointments.location_id,
    appointments.created_at as appointment_booked_at,
    appointments.scheduled_at as appointment_scheduled_at,
    locations.created_at as location_go_live_at

from {{ ref('stg_caremetrics__appointments') }} as appointments

inner join {{ ref('stg_caremetrics__locations') }} as locations
    on appointments.location_id = locations.location_id

where
    appointments.scheduled_at < locations.created_at
    or appointments.created_at < locations.created_at
