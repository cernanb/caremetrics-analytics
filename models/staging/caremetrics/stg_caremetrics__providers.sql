with source as (

    select * from {{ source('caremetrics', 'providers') }}

),

renamed as (

    select
        id as provider_id,
        first_name,
        last_name,
        location_id,
        active as is_active,
        specialty,
        created_at,
        updated_at

    from source

)

select * from renamed
