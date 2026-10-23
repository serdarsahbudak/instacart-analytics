with order_products as (
    select * from {{ ref('stg_order_products') }}
),

products as (
    select * from {{ ref('stg_products') }}
),

aisles as (
    select * from {{ ref('stg_aisles') }}
),

departments as (
    select * from {{ ref('stg_departments') }}
),

enriched as (
    select
        op.order_id,
        op.product_id,
        op.add_to_cart_order,
        op.reordered,
        op.order_set,
        p.product_name,
        p.aisle_id,
        p.department_id,
        a.aisle,
        d.department
    from order_products op
    left join products p 
        on op.product_id = p.product_id
    left join aisles a 
        on p.aisle_id = a.aisle_id
    left join departments d 
        on p.department_id = d.department_id
)

select * from enriched