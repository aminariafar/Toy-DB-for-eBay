-- Data-quality checks  
-- Total number of users 
SELECT COUNT(*) AS total_users
FROM user_account;

-- Sellers who still have items in “draft” status
SELECT seller_id, COUNT(*) AS draft_items
FROM   item
WHERE  status = 'draft'
GROUP  BY seller_id
HAVING COUNT(*) > 0;

-- Item count per category (highest → lowest) 
SELECT c.category_name,
       COUNT(i.item_id) AS total_items
FROM   category c
LEFT   JOIN item i ON i.category_id = c.category_id
GROUP  BY c.category_name
ORDER  BY total_items DESC;

-- Auction & listing operations 
-- Ten active auctions that finish soonest 
SELECT item_id, title, current_price, end_time
FROM   item
WHERE  status = 'active'
ORDER  BY end_time
LIMIT  10;

-- Bid history for item 1
SELECT bid_id, bidder_id, bid_amount, bid_time
FROM   bid
WHERE  item_id = 1
ORDER  BY bid_time DESC;

-- Top-5 items by highest bid amount 
SELECT i.item_id, i.title, MAX(b.bid_amount) AS highest_bid
FROM   item i
JOIN   bid  b USING (item_id)
GROUP  BY i.item_id, i.title
ORDER  BY highest_bid DESC
LIMIT  5;

-- Cart, order, payment workflow 

-- All carts that are currently active
SELECT cart_id, user_id, created_at
FROM   cart
WHERE  status = 'active';

-- Cart-total for cart 1 
SELECT c.cart_id,
       SUM(ci.desired_quantity * ci.price_at_addition) AS cart_total
FROM   cart       c
JOIN   cart_item  ci USING (cart_id)
WHERE  c.cart_id = 1
GROUP  BY c.cart_id;

-- Delivered vs. in-flight shipments per order 
SELECT o.order_id,
       COUNT(*) FILTER (WHERE s.shipping_status = 'delivered')     AS delivered,
       COUNT(*) FILTER (WHERE s.shipping_status <> 'delivered')    AS in_flight
FROM   customer_order o
JOIN   shipping       s USING (order_id)
GROUP  BY o.order_id;

-- Most active buyers in the last 30 days (order count) 
SELECT buyer_id,
       COUNT(*) AS orders_last_30d
FROM   customer_order
WHERE  order_date > CURRENT_DATE - 30
GROUP  BY buyer_id
ORDER  BY orders_last_30d DESC;

-- Paid revenue per calendar month 
SELECT TO_CHAR(payment_date, 'YYYY-MM') AS ym,
       SUM(amount)                      AS revenue
FROM   payment_transaction
WHERE  payment_status = 'paid'
GROUP  BY ym
ORDER  BY ym;

-- Wallet / finance 

-- Five wallets with the highest balance 
SELECT user_id, balance
FROM   wallet
ORDER  BY balance DESC
LIMIT  5;

-- Coupons & tax configuration 

SELECT code, usage_count, expiration_date
FROM   discount_code
WHERE  coupon_id = 1;


-- Most-used coupons 
SELECT code, usage_count, usage_limit
FROM   discount_code
ORDER  BY usage_count DESC;

-- Number of orders that used each coupon 
SELECT d.code,
       COUNT(*) AS orders_used
FROM   customer_order o
JOIN   discount_code d USING (coupon_id)
GROUP  BY d.code;

-- Inventory & stock levels 

-- Inventories and their addresses 
SELECT i.inventory_id,
       a.city,
       a.street
FROM   inventory i
JOIN   address   a USING (address_id);

-- Items with fewer than 10 units remaining 
SELECT ii.inventory_id,
       ii.item_id,
       ii.quantity
FROM   inventory_item ii
WHERE  ii.quantity < 10
ORDER  BY ii.quantity;

-- Messaging & user interactions 

-- Message count between each sender / receiver pair 
SELECT sender_id,
       receiver_id,
       COUNT(*) AS msg_count
FROM   message
GROUP  BY sender_id, receiver_id;

-- Unread (“sent”) messages per user 
SELECT u.username,
       COUNT(m.message_id) AS unread
FROM   user_account u
JOIN   message      m ON m.receiver_id = u.user_id
WHERE  m.message_status = 'sent'
GROUP  BY u.username;

-- Most recent incoming message for each user 
WITH ranked AS (
    SELECT message_id,
           receiver_id,
           sender_id,
           message_content,
           sent_time,
           ROW_NUMBER() OVER (PARTITION BY receiver_id
                              ORDER BY sent_time DESC) AS rn
    FROM   message)
SELECT receiver_id,
       sender_id,
       message_content,
       sent_time
FROM   ranked
WHERE  rn = 1;

-- Browse / view analytics 

-- Top-5 most-viewed items 
SELECT item_id,
       COUNT(*) AS views
FROM   viewed_items
GROUP  BY item_id
ORDER  BY views DESC
LIMIT  5;

-- Time difference between consecutive views per user 
SELECT user_id,
       item_id,
       save_date,
       LAG(save_date) OVER (PARTITION BY user_id ORDER BY save_date) AS prev_view
FROM   viewed_items
ORDER  BY user_id, save_date;

--  Composite / advanced analytics 

-- Gap between current price and highest bid 
WITH bid_stats AS (
    SELECT item_id,
           COUNT(*)      AS bids,
           MAX(bid_amount) AS top_bid
    FROM   bid
    GROUP  BY item_id)
SELECT i.item_id,
       i.title,
       b.bids,
       b.top_bid,
       i.current_price,
       b.top_bid - i.current_price AS delta
FROM   item i
JOIN   bid_stats b USING (item_id)
ORDER  BY delta DESC;

-- Buyer loyalty index (item variety and purchase volume) 
SELECT buyer_id,
       COUNT(DISTINCT item_id)                     AS unique_items,
       SUM(desired_quantity)                       AS total_units,
       ROUND(SUM(desired_quantity * price_at_addition) / 1e6, 1)
                                                   AS total_rials_mn
FROM   customer_order o
JOIN   cart_item     ci USING (cart_id)
GROUP  BY buyer_id
ORDER  BY total_units DESC;

-- Daily auction activity for the past 7 days 
SELECT TO_CHAR(bid_time, 'YYYY-MM-DD') AS day,
       COUNT(*)                        AS bids,
       COUNT(DISTINCT bidder_id)       AS bidders
FROM   bid
WHERE  bid_time >= CURRENT_DATE - 7
GROUP  BY day
ORDER  BY day DESC;

-- Purchases below the reserve price (bargains) 
SELECT u.username,
       SUM(CASE WHEN ci.price_at_addition < i.reserve_price THEN 1 ELSE 0 END) AS bargains
FROM   cart_item    ci
JOIN   item         i  USING (item_id)
JOIN   cart         c  USING (cart_id)
JOIN   user_account u  ON u.user_id = c.user_id
GROUP  BY u.username
ORDER  BY bargains DESC;

-- User activity summary (wishlist, messages, bids) 
SELECT u.username,
       (SELECT COUNT(*) FROM wishlist w WHERE w.user_id = u.user_id) AS wish_ct,
       (SELECT COUNT(*) FROM message  m WHERE m.sender_id = u.user_id) AS msgs_sent,
       (SELECT COUNT(*) FROM bid      b WHERE b.bidder_id = u.user_id) AS bids_made
FROM   user_account u
ORDER  BY wish_ct DESC;