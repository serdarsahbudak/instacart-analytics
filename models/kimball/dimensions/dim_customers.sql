with customers as (
    select * from {{ ref('mart_customers') }}
),

final as (
    select
        user_id,
        total_orders,
        latest_order_number,
        avg_basket_size,
        avg_days_between_orders,
        avg_reorder_rate_pct,
        customer_segment
    from customers
)

select * from final