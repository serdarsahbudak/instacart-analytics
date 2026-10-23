with prior as (
    select 
        order_id,
        product_id,
        add_to_cart_order,
        reordered,
        'prior' as order_set
    from {{source('raw_instacart', 'order_products_prior')}}
),

train as (
    select 
        order_id,
        product_id,
        add_to_cart_order,
        reordered,
        'train' as order_set
    from {{source('raw_instacart', 'order_products_train')}}
),

combined as (
    select * from prior
    union all
    select * from train
)

select * from combined