with source as (

    select * from {{ source('caremetrics', 'claims') }}

),

renamed as (

    select
        id as claim_id,
        encounter_id,
        patient_id,
        provider_id,
        payer_id,
        status as claim_status,
        amount_billed,
        amount_paid,
        submitted_at,
        created_at,
        updated_at

    from source

)

select * from renamed
