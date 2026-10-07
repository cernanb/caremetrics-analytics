{{ config(severity='warn') }}

-- A pediatrics provider should only see patients who are under 18 on the day of their visit.
-- The source doesn't enforce it. A clinic could have a valid exception, which is why this test warns.
-- The visit date is the clinic's local (Denver) calendar date: an evening visit is already the next day in UTC.
-- Returns the violating appointments; the test passes when no rows come back.

select
    appointments.appointment_id,
    patients.patient_id,
    providers.provider_id,
    patients.date_of_birth,
    date(appointments.scheduled_at, 'America/Denver') as visit_date

from {{ ref('stg_caremetrics__appointments') }} as appointments

inner join {{ ref('stg_caremetrics__patients') }} as patients
    on appointments.patient_id = patients.patient_id
inner join {{ ref('stg_caremetrics__providers') }} as providers
    on appointments.provider_id = providers.provider_id

where providers.specialty = 'Pediatrics'
    and date(appointments.scheduled_at, 'America/Denver') >= date_add(patients.date_of_birth, interval 18 year)
