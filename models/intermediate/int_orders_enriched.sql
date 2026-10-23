with orders as (
    select * from {{ref('stg_orders')}}
),

order_products as (
    select 
        order_id,
        count(product_id) as basket_size,
        sum(reordered) as reordered_items,
        sum(case when reordered = 0 then 1 else 0 end) as new_items
    from {{ref('stg_order_products')}}
    group by order_id
),

enriched as (
    select
        o.order_id,
        o.user_id,
        o.order_number,
        o.order_day_of_week,
        o.order_hour_of_day,
        o.days_since_prior_order,
        op.basket_size,
        op.reordered_items,
        op.new_items,
        case
            when o.order_number = 1 then true
            else false
        end as is_first_order
    from orders o
    left join order_products op on o.order_id = op.order_id
)

select * from enriched