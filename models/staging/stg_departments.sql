with source as (
    select * from {{source ('raw_instacart', 'departments')}}
),

renamed as (
    select 
        department_id,
        department
    from source
)

select * from renamed