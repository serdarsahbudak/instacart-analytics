with order_products as (
    select * from {{ ref('int_order_products_enriched') }}
),

product_stats as (
    select
        product_id,
        product_name,
        aisle,
        department,
        count(order_id)                                              as total_orders,
        sum(reordered)                                               as total_reorders,
        round(safe_divide(sum(reordered), count(order_id)) * 100, 2) as reorder_rate_pct,
        round(avg(add_to_cart_order), 2)                             as avg_cart_position
    from order_products
    group by
        product_id,
        product_name,
        aisle,
        department
)

select * from product_stats