with products as (
    select * from {{ ref('stg_products') }}
),

aisles as (
    select * from {{ ref('stg_aisles') }}
),

departments as (
    select * from {{ ref('stg_departments') }}
),

final as (
    select
        products.product_id,
        products.product_name,
        aisles.aisle_id,
        aisles.aisle,
        departments.department_id,
        departments.department
    from products
    left join aisles
        on products.aisle_id = aisles.aisle_id
    left join departments
        on products.department_id = departments.department_id
)

select * from final