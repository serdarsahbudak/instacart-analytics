with order_products as (
    select * from {{ ref('stg_order_products') }}
),

orders as (
    select * from {{ ref('int_orders_enriched') }}
),

dim_products as (
    select * from {{ ref('dim_products') }}
),

dim_customers as (
    select * from {{ ref('dim_customers') }}
),

final as (
    select
        op.order_id,
        op.product_id,
        o.user_id,
        op.add_to_cart_order,
        op.reordered,
        op.order_set,
        o.order_number,
        o.order_day_of_week,
        o.order_hour_of_day,
        o.days_since_prior_order,
        o.is_first_order
    from order_products op
    left join orders o
        on op.order_id = o.order_id
    left join dim_products dp
        on op.product_id = dp.product_id
    left join dim_customers dc
        on o.user_id = dc.user_id
)

select * from final