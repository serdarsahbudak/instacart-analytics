with orders as (
    select * from {{ ref('int_orders_enriched') }}
),

customer_stats as (
    select
        user_id,
        count(order_id)                                             as total_orders,
        max(order_number)                                           as latest_order_number,
        round(avg(basket_size), 2)                                  as avg_basket_size,
        round(avg(days_since_prior_order), 2)                       as avg_days_between_orders,
        round(
            safe_divide(sum(reordered_items), sum(basket_size)) * 100
        , 2)                                                        as avg_reorder_rate_pct,
        case
            when count(order_id) = 1 then 'one_time'
            when count(order_id) between 2 and 5 then 'occasional'
            when count(order_id) between 6 and 10 then 'regular'
            else 'loyal'
        end as customer_segment
    from orders
    group by user_id
)

select * from customer_stats