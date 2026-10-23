with source as (
    select * from {{ source('raw_instacart', 'orders') }}
),

renamed as (
    select
        order_id,
        user_id,
        order_number,
        order_dow as order_day_of_week,
        order_hour_of_day,
        days_since_prior_order
    from source
)

select * from renamed