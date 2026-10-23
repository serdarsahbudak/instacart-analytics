with orders as (
    select * from {{ ref('int_orders_enriched') }}
),

final as (
    select
        order_id,
        user_id,
        order_number,
        order_day_of_week,
        order_hour_of_day,
        days_since_prior_order,
        basket_size,
        reordered_items,
        new_items,
        is_first_order,
        round(safe_divide(reordered_items, basket_size) * 100, 2) as reorder_rate_pct
    from orders
)

select * from final