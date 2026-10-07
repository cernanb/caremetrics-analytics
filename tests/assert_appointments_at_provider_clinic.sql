{{ config(severity='warn') }}

-- An appointment should take place at its provider's clinic.
-- Warns rather than fails: providers store only their current clinic,
-- so a valid transfer would flag their past appointments.
-- Returns violating appointments; the test passes when no rows come back.

select
    appointments.appointment_id,
    appointments.provider_id,
    appointments.location_id as appointment_location_id,
    providers.location_id as provider_location_id

from {{ ref('stg_caremetrics__appointments') }} as appointments

inner join {{ ref('stg_caremetrics__providers') }} as providers
    on appointments.provider_id = providers.provider_id

where appointments.location_id != providers.location_id
