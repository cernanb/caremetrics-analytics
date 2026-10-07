-- An appointment is booked (created_at) no later than the time it's scheduled for (scheduled_at).
-- Returns the violating appointments; the test passes when no rows come back.

select
    appointment_id,
    scheduled_at,
    created_at as booked_at

from {{ ref('stg_caremetrics__appointments') }}

where created_at > scheduled_at
