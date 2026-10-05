with source as (

    select * from {{ source('caremetrics', 'encounters') }}

),

renamed as (

    select
        id as encounter_id,
        appointment_id,
        patient_id,
        provider_id,
        location_id,
        started_at,
        completed_at,
        created_at,
        updated_at

    from source

)

select * from renamed
