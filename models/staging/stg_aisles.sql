with source as (
    select * from {{ source ('raw_instacart', 'aisles')}}
),

renamed as (
    select 
        aisle_id,
        aisle
    from source
)

select * from renamed