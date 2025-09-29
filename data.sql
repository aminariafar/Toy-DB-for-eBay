-- Categories
INSERT INTO category (category_id, category_name, category_description, parent_category_id) VALUES
  (1, 'Digital Goods',         'Electronic and digital devices',             NULL),
  (2, 'Mobile Phones',         'Phones and accessories',                     1),
  (3, 'Laptops',               'Various laptops and ultrabooks',             1),
  (4, 'Fashion & Apparel',     'Clothing, footwear and accessories',         NULL),
  (5, 'Books',                 'Books and magazines',                        NULL),
  (6, 'Academic Books',        'University reference books',                 5);

-- User accounts  (3 sellers, 5 buyers)
INSERT INTO user_account
  (user_id, username,           email,                 password_hash,
   first_name,  last_name,  phone,        rating)
VALUES
  (1, 'ali.rezaei',     'ali@example.com',     'hash1', 'Ali',      'Rezaei',     '09120000001', 4.7),
  (2, 'fatemeh.jafari', 'fatemeh@example.com', 'hash2', 'Fatemeh',  'Jafari',     '09120000002', 4.9),
  (3, 'mehrdad.karimi', 'mehrdad@example.com', 'hash3', 'Mehrdad',  'Karimi',     '09120000003', 4.3),
  (4, 'sara.nasiri',    'sara@example.com',    'hash4', 'Sara',     'Nasiri',     '09120000004', 4.1),
  (5, 'reza.ahmadi',    'reza@example.com',    'hash5', 'Reza',     'Ahmadi',     '09120000005', 3.8),
  (6, 'niloufar.moh',   'niloufar@example.com','hash6', 'Niloufar', 'Mohammadi',  '09120000006', 4.6),
  (7, 'hamed.sole',     'hamed@example.com',   'hash7', 'Hamed',    'Soleimani',  '09120000007', 4.4),
  (8, 'yasin.talebi',   'yasin@example.com',   'hash8', 'Yasin',    'Talebi',     '09120000008', 4.2);


 -- Addresses  (shipping + inventory)
INSERT INTO address
  (address_id, user_id, street,               city,     state,              zip_code, country, is_inventory)
VALUES
  -- Ali: home + warehouse
  (1, 1,  'Azadi St.',                     'Tehran',  'Tehran',          '11369',  'Iran', FALSE),
  (2, 1,  'Warehouse No.1, Km 10 Special Rd.', 'Tehran',  'Tehran',          '14965',  'Iran', TRUE),
  -- Fatemeh: home + warehouse
  (3, 2,  'Valiasr St.',                    'Isfahan', 'Isfahan',         '81476',  'Iran', FALSE),
  (4, 2,  'Central Warehouse, Mahmoodabad IZ', 'Isfahan', 'Isfahan',         '81988',  'Iran', TRUE),
  -- Mehrdad: home / warehouse
  (5, 3,  'Moallem Blvd.',                  'Shiraz',  'Fars',            '71963',  'Iran', TRUE),
  -- buyers
  (6, 4,  'Daneshgah St.',                  'Tehran',  'Tehran',          '11557',  'Iran', FALSE),
  (7, 5,  'Keshavarz Blvd.',                'Mashhad', 'Razavi Khorasan', '91856',  'Iran', FALSE),
  (8, 6,  'Shariati St.',                   'Karaj',   'Alborz',          '31556',  'Iran', FALSE),
  (9, 7,  'Imam Khomeini St.',               'Tabriz',  'East Azerbaijan', '51367',  'Iran', FALSE),
  (10,8,  'Daneshjoo St.',                  'Ahvaz',   'Khuzestan',       '61565',  'Iran', FALSE);


 -- Wallets  (init balance in Tomans)
INSERT INTO wallet (wallet_id, user_id, balance) VALUES
  (1,1,50000000), (2,2,60000000), (3,3,30000000),
  (4,4,20000000), (5,5,10000000), (6,6,40000000),
  (7,7,25000000), (8,8,15000000);

 -- Seller profiles
INSERT INTO seller_profile
  (user_id, business_name,     business_description,                 is_verified)
VALUES
  (1, 'Ali Store',           'Selling various mobile phones & accessories', TRUE),
  (2, 'Digi Laptop Shop',    'Specialised in laptops & parts',              TRUE),
  (3, 'Mehrdad Bookstore',   'Academic and general books',                  FALSE);


 -- Inventories  (each linked to an is_inventory address)
INSERT INTO inventory (inventory_id, address_id) VALUES
  (1,2),  -- Ali
  (2,4),  -- Digi Laptop Shop
  (3,5);  -- Mehrdad

/*  Discount codes */
INSERT INTO discount_code
  (coupon_id, item_id, code,      discount_type, discount_value,
   expiration_date,             min_order_amount, usage_count, usage_limit)
VALUES
  (1,        NULL,   'WELCOME10', 'percentage',   10,
   '2025-12-31 23:59:59+03:30',   NULL,            0,          1000);


 -- Items  (auction / listing)
INSERT INTO item
  (item_id, seller_id, category_id, title, description,
   condition, start_price, reserve_price, current_price,
   start_time,            end_time,              status)
VALUES
  (1,1,2,'Xiaomi Redmi Note 12 Phone','128GB storage, 6GB RAM','new',
        80000000,100000000,80000000,
        '2025-06-09 10:00:00+03:30','2025-06-16 10:00:00+03:30','draft'),
  (2,1,2,'iPhone 13 Silicone Case','Black color','new',
        3000000,5000000,3000000,
        '2025-06-09 10:05:00+03:30','2025-06-12 10:05:00+03:30','draft'),
  (3,2,3,'Asus VivoBook K513 Laptop','Core i5 / 8GB / 512 SSD','refurbished',
        280000000,300000000,280000000,
        '2025-06-09 11:00:00+03:30','2025-06-18 11:00:00+03:30','draft'),
  (4,2,3,'Logitech M185 Mouse','Used in good condition','used',
        4000000,6000000,4000000,
        '2025-06-09 11:30:00+03:30','2025-06-11 11:30:00+03:30','draft'),
  (5,3,6,'Advanced Operating Systems Book','Printed 2023, new','new',
        15000000,18000000,15000000,
        '2025-06-09 12:00:00+03:30','2025-06-20 12:00:00+03:30','draft'),
  (6,3,6,'Electrical Engineering Book Set (5 vols.)','Second-hand, clean','used',
        5000000,7000000,5000000,
        '2025-06-09 12:30:00+03:30','2025-06-13 12:30:00+03:30','draft');


 -- Inventory items
INSERT INTO inventory_item (inventory_id, item_id, quantity, sku) VALUES
  (1,1, 20,'RN12-128-6'),
  (1,2, 50,'CASE-IP13-BLK'),
  (2,3,  7,'VBK513-I5'),
  (2,4, 40,'LOGI-M185'),
  (3,5, 15,'OS-ADV-1402'),
  (3,6, 25,'EE-SET-USED');


-- Bids  (trigger keeps current_price in sync)
INSERT INTO bid
  (bid_id, item_id, bidder_id, bid_amount, bid_time) VALUES
  (1,1,4, 85000000,'2025-06-09 14:00:00+03:30'),
  (2,1,5, 90000000,'2025-06-09 15:00:00+03:30'),
  (3,3,6,285000000,'2025-06-09 15:30:00+03:30');


-- Wish-list and viewed items
INSERT INTO wishlist (user_id, item_id) VALUES
  (4,3),(4,5),(5,1),(6,1),(7,3);

INSERT INTO viewed_items (viewed_item_id, user_id, item_id) VALUES
  (1,4,1),(2,4,2),(3,5,3),(4,6,4),(5,6,5);


-- Active carts for two buyers
INSERT INTO cart (cart_id, user_id, status) VALUES
  (1,4,'active'),
  (2,5,'active');

INSERT INTO cart_item
  (cart_id, item_id, desired_quantity, price_at_addition) VALUES
  (1,2,1,3000000),   -- Case ×1
  (1,4,2,4000000),   -- Mouse ×2
  (2,6,1,5000000);   -- EE book set ×1


-- Order creation (no coupon)
-- Update cart 1 to 'ordered'
UPDATE cart
SET    status = 'ordered',
       updated_at = NOW()
WHERE  cart_id = 1;


INSERT INTO customer_order
  (order_id, cart_id, buyer_id, coupon_id, order_status)
VALUES
  (1, 1, 4, 1, 'pending');


-- Shipping & Payment
INSERT INTO shipping
  (shipping_id, order_id, shipping_address_id,
   shipping_method, shipping_cost, shipping_status)
VALUES
  (1, 1, 6, 'Express Post', 150000, 'pending');

-- Cart total = 11 000 000  
-- 10 % discount  = –1 100 000  
-- + shipping     = 150 000  
-- → final amount = 10 050 000
INSERT INTO payment_transaction
  (payment_id, order_id, amount,  payment_status)
VALUES
  (1, 1, 10050000, 'paid');

INSERT INTO wallet_transaction
  (wallet_tx_id, wallet_id, tx_type, amount,
   payment_id,  status,    description)
VALUES
  (1,           4,        'payment', 10050000,
   1,           'completed',
   'Payment for order #1 (WELCOME10 applied)');


-- Private messaging
INSERT INTO message
  (message_id, sender_id, receiver_id, message_content) VALUES
  (1,4,1,'Hi, is the blue color of this case available too?'),
  (2,1,4,'Hi, yes I will add it to stock tomorrow.');


