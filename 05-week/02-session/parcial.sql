SELECT 
    u.user_name, 
    r.name
FROM
    user_account u
    INNER JOIN user_role ur ON u.id = ur.user_id
    INNER JOIN role r ON ur.role_id = r.id
WHERE 
    r.name = 'invitado';


SELECT
    DISTINCT(r.name) AS list_role
FROM 
    user_account u
    INNER JOIN user_role ur ON u.id = ur.user_id
    INNER JOIN role r ON ur.role_id = r.id

SELECT 
    p.name,
    bi.price * bi.count AS total_pay_product
FROM
    bill b
    JOIN bill_item bi on b.id = bi.bill_id
    LEFT JOIN product p ON bi.product_id = p.id

SELECT 
    p.name,
    bi.price * bi.count AS total_pay_product
FROM
    bill b
    INNER JOIN bill_item bi on b.id = bi.bill_id
    LEFT JOIN product p ON bi.product_id = p.id

SELECT 
    p.name,
    bi.price * bi.count AS total_pay_product
FROM
    bill b
    INNER JOIN bill_item bi on b.id = bi.bill_id
    INNER JOIN product p ON bi.product_id = p.id