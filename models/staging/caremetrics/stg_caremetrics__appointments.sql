with source as (

    select * from {{ source('caremetrics', 'appointments') }}

),

renamed as (

    select
        id as appointment_id,
        patient_id,
        provider_id,
        location_id,
        scheduled_at,
        status as appointment_status,
        appointment_type,
        created_at,
        updated_at

    from source

)

select * from renamed
