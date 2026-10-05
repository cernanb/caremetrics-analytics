with source as (

    select * from {{ source('caremetrics', 'locations') }}

),

renamed as (

    select
        id as location_id,
        name as location_name,
        city,
        state,
        created_at,
        updated_at

    from source

)

select * from renamed
