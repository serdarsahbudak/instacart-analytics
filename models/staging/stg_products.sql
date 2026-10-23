with source as (
    select * from {{ source('raw_instacart', 'products')}}
),

renamed as(
    select
        product_id,
        product_name,
        aisle_id,
        department_id
    from source
)

select * from renamed