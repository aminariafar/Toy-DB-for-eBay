-- Dropping everything:
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public; 
-----------------------------------------------------

-- Custom ENUM types
CREATE TYPE condition_enum AS ENUM ('new','used','refurbished','other');
CREATE TYPE item_status_enum AS ENUM ('draft','active','ended','sold','cancelled');
CREATE TYPE payment_status_enum AS ENUM ('pending','paid','refunded','cancelled');
CREATE TYPE shipping_status_enum AS ENUM ('pending','shipped','delivered','returned');
CREATE TYPE order_status_enum AS ENUM ('pending','paid','shipped','delivered','cancelled');
CREATE TYPE discount_type_enum AS ENUM ('percentage','fixed');
CREATE TYPE message_status_enum AS ENUM ('sent','delivered','seen');
CREATE TYPE wallet_tx_type_enum AS ENUM ('deposit','payment','refund');
CREATE TYPE wallet_tx_status_enum AS ENUM ('pending','completed','failed');
CREATE TYPE cart_status_enum AS ENUM ('active','ordered','cancelled');

-- Core tables
CREATE TABLE user_account (
    user_id           BIGSERIAL PRIMARY KEY,
    username          VARCHAR(50)    NOT NULL UNIQUE,
    email             VARCHAR(120)   NOT NULL UNIQUE,
    password_hash     VARCHAR(255)   NOT NULL,
    first_name        VARCHAR(50)    NOT NULL,
    last_name         VARCHAR(50)    NOT NULL,
    phone             VARCHAR(25),
    registration_date TIMESTAMPTZ    NOT NULL DEFAULT now(),
    rating            NUMERIC(2,1)   CHECK (rating BETWEEN 0 AND 5)
);

-- if the address is not for a buyer, it's for a seller. :))
-- we assumed that all of inventories belong to sellers. (eg. no ebay inventory)
CREATE TABLE address (
    address_id   BIGSERIAL PRIMARY KEY,
    user_id      BIGINT      NOT NULL
                   REFERENCES user_account(user_id)
                   ON DELETE CASCADE,
    street       VARCHAR(255) NOT NULL,
    city         VARCHAR(100) NOT NULL,
    state        VARCHAR(100),
    zip_code     VARCHAR(20)  NOT NULL,
    country      VARCHAR(100) NOT NULL,
    is_inventory BOOLEAN      NOT NULL DEFAULT FALSE
);

CREATE TABLE category (
    category_id          BIGSERIAL PRIMARY KEY,
    category_name        VARCHAR(120) NOT NULL UNIQUE,
    category_description TEXT,
    parent_category_id   BIGINT
                         REFERENCES category(category_id)
                         ON UPDATE CASCADE
                         ON DELETE SET NULL
);



-- Main auction objects
CREATE TABLE item (
    item_id        BIGSERIAL PRIMARY KEY,
    seller_id      BIGINT     NOT NULL
                   REFERENCES user_account(user_id)
                   ON UPDATE CASCADE
                   ON DELETE RESTRICT,
    category_id    BIGINT
                   REFERENCES category(category_id)
                   ON UPDATE CASCADE
                   ON DELETE SET NULL,
    title          VARCHAR(200)   NOT NULL,
    description    TEXT,
    condition      condition_enum NOT NULL,
    start_price    NUMERIC(12,2)  NOT NULL CHECK (start_price > 0),
    reserve_price  NUMERIC(12,2)  CHECK (reserve_price >= start_price),
    current_price  NUMERIC(12,2)  NOT NULL DEFAULT 0,
    start_time     TIMESTAMPTZ    NOT NULL DEFAULT now(),
    end_time       TIMESTAMPTZ    NOT NULL,
    status         item_status_enum NOT NULL DEFAULT 'draft',
    CONSTRAINT check_item_dates CHECK (end_time > start_time)
);

CREATE INDEX idx_item_seller     ON item(seller_id);
CREATE INDEX idx_item_category   ON item(category_id);
CREATE INDEX idx_item_status_end ON item(status, end_time);



-- Cart and related Items
CREATE TABLE cart (
    cart_id     BIGSERIAL PRIMARY KEY,
    user_id     BIGINT    NOT NULL
               REFERENCES user_account(user_id)
               ON DELETE CASCADE,
    status      cart_status_enum NOT NULL DEFAULT 'active',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enforce at most one active cart per user via a partial unique index
CREATE UNIQUE INDEX ux_cart_user_active ON cart(user_id) WHERE status = 'active';

CREATE TABLE cart_item (
    cart_id            BIGINT NOT NULL
                       REFERENCES cart(cart_id)
                       ON DELETE CASCADE,
    item_id            BIGINT NOT NULL
                       REFERENCES item(item_id)
                       ON DELETE RESTRICT,
    added_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    desired_quantity   INT NOT NULL DEFAULT 1 CHECK (desired_quantity > 0),
    price_at_addition  NUMERIC(12,2) NOT NULL CHECK (price_at_addition >= 0),
    PRIMARY KEY (cart_id, item_id)
);
CREATE INDEX idx_cart_user       ON cart(user_id);
CREATE INDEX idx_cartitem_item   ON cart_item(item_id);



-- Inventories
CREATE TABLE inventory (
    inventory_id BIGSERIAL PRIMARY KEY,
    address_id   BIGINT NOT NULL
                 REFERENCES address(address_id)
                 ON DELETE RESTRICT
);

CREATE TABLE inventory_item (
    inventory_id BIGINT NOT NULL
                 REFERENCES inventory(inventory_id)
                 ON DELETE CASCADE,
    item_id      BIGINT NOT NULL
                 REFERENCES item(item_id)
                 ON DELETE CASCADE,
    quantity     INT    NOT NULL CHECK (quantity >= 0),
    sku          VARCHAR(80),
    PRIMARY KEY (inventory_id, item_id)
);
CREATE INDEX idx_inventory_item_item ON inventory_item(item_id);


-- User-to-user messaging
CREATE TABLE message (
    message_id       BIGSERIAL PRIMARY KEY,
    sender_id        BIGINT NOT NULL
                     REFERENCES user_account(user_id)
                     ON DELETE CASCADE,
    receiver_id      BIGINT NOT NULL
                     REFERENCES user_account(user_id)
                     ON DELETE CASCADE,
    message_content  TEXT    NOT NULL,
    sent_time        TIMESTAMPTZ NOT NULL DEFAULT now(),
    message_status   message_status_enum NOT NULL DEFAULT 'sent'
);
CREATE INDEX idx_message_receiver ON message(receiver_id);

-- wishlist
CREATE TABLE wishlist (
    user_id  BIGINT NOT NULL
             REFERENCES user_account(user_id)
             ON DELETE CASCADE,
    item_id  BIGINT NOT NULL
             REFERENCES item(item_id)
             ON DELETE CASCADE,
    saved_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, item_id)
);

-- Seller Profile
CREATE TABLE seller_profile (
    user_id            BIGINT PRIMARY KEY
                      REFERENCES user_account(user_id)
                      ON DELETE CASCADE,
    business_name      VARCHAR(120),
    business_description TEXT,
    is_verified        BOOLEAN NOT NULL DEFAULT FALSE,
    profile_image_url  TEXT
);



-- Bids & Trigger to update current_price
CREATE TABLE bid (
    bid_id     BIGSERIAL PRIMARY KEY,
    item_id    BIGINT NOT NULL
              REFERENCES item(item_id)
              ON DELETE CASCADE,
    bidder_id  BIGINT NOT NULL
              REFERENCES user_account(user_id)
              ON DELETE RESTRICT,
    bid_amount NUMERIC(12,2) NOT NULL CHECK (bid_amount > 0),
    bid_time   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_bid_item_time ON bid(item_id, bid_time DESC);

-- Trigger: initialize current_price when item is created
CREATE OR REPLACE FUNCTION trg_initialize_current_price()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    -- Set current_price to start_price when item is created
    IF NEW.current_price = 0 THEN
        NEW.current_price = NEW.start_price;
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER item_before_insert
BEFORE INSERT ON item
FOR EACH ROW
EXECUTE FUNCTION trg_initialize_current_price();

-- Trigger: keep item.current_price in sync with highest bid
CREATE OR REPLACE FUNCTION trg_update_current_price()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    UPDATE item
       SET current_price = GREATEST(NEW.bid_amount, current_price),
           status        = CASE WHEN status = 'draft' THEN 'active' ELSE status END
     WHERE item_id = NEW.item_id;
    RETURN NEW;
END $$;

CREATE TRIGGER bid_after_insert
AFTER INSERT ON bid
FOR EACH ROW
EXECUTE FUNCTION trg_update_current_price();



-- Wallet and Transactions
-- Each user has one wallet
CREATE TABLE wallet (
    wallet_id    BIGSERIAL PRIMARY KEY,
    user_id      BIGINT NOT NULL UNIQUE
                 REFERENCES user_account(user_id)
                 ON DELETE CASCADE,
    balance      NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (balance >= 0),
    last_updated TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- Discounts 
CREATE TABLE discount_code (
    coupon_id        BIGSERIAL PRIMARY KEY,
    item_id          BIGINT
                     REFERENCES item(item_id)
                     ON DELETE CASCADE,
    code             VARCHAR(80) NOT NULL UNIQUE,
    discount_type    discount_type_enum NOT NULL,
    discount_value   NUMERIC(10,2) NOT NULL CHECK (discount_value > 0),
    expiration_date  TIMESTAMPTZ,
    min_order_amount NUMERIC(10,2),
    usage_count      INT NOT NULL DEFAULT 0 CHECK (usage_count >= 0),
    usage_limit      INT NOT NULL DEFAULT 2147483646 CHECK (usage_limit > 0)
);



CREATE TABLE customer_order (
    order_id      BIGSERIAL PRIMARY KEY,
    cart_id       BIGINT NOT NULL
                  REFERENCES cart(cart_id)
                  ON DELETE RESTRICT,
    buyer_id      BIGINT NOT NULL
                  REFERENCES user_account(user_id)
                  ON DELETE RESTRICT,
    order_date    TIMESTAMPTZ NOT NULL DEFAULT now(),
    coupon_id     BIGINT
                  REFERENCES discount_code(coupon_id)
                  ON UPDATE CASCADE
                  ON DELETE SET NULL,
    order_status  order_status_enum NOT NULL DEFAULT 'pending'
);
CREATE INDEX idx_order_cart ON customer_order(cart_id);
CREATE INDEX idx_order_buyer ON customer_order(buyer_id);

------------ Trigger function to enforce & increment usage_count
CREATE OR REPLACE FUNCTION trg_apply_coupon()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  dc           discount_code%ROWTYPE;
  order_total  NUMERIC(12,2);
BEGIN
  -- If there is no coupon, do nothing
  IF NEW.coupon_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Lock the coupon row for concurrency control
  SELECT * INTO dc
  FROM discount_code
  WHERE coupon_id = NEW.coupon_id
  FOR UPDATE;

  -- Calculate total amount of the cart including shipping
  SELECT SUM(ci.desired_quantity * ci.price_at_addition) + 
         COALESCE((SELECT shipping_cost FROM shipping WHERE order_id = NEW.order_id), 0)
    INTO order_total
  FROM cart_item ci
  WHERE ci.cart_id = NEW.cart_id;

  -- (1) Expiration check
  IF dc.expiration_date IS NOT NULL
     AND NOW() > dc.expiration_date THEN
    RAISE EXCEPTION 'Coupon % expired on %', dc.code, dc.expiration_date;
  END IF;

  -- (2) Minimum order amount check
  IF dc.min_order_amount IS NOT NULL
     AND order_total < dc.min_order_amount THEN
    RAISE EXCEPTION 'Order amount % is below minimum % for coupon %',
          order_total, dc.min_order_amount, dc.code;
  END IF;

  -- (3) Usage limit check
  IF dc.usage_count >= dc.usage_limit THEN
    RAISE EXCEPTION 'Coupon % has reached its usage limit of %',
          dc.code, dc.usage_limit;
  END IF;

  -- (4) All checks passed → increment usage count
  UPDATE discount_code
  SET    usage_count = usage_count + 1
  WHERE  coupon_id = NEW.coupon_id;

  RETURN NEW;
END;
$$;

------------ Install the trigger on customer_order
CREATE TRIGGER trg_apply_coupon_before_order
BEFORE INSERT OR UPDATE ON customer_order
FOR EACH ROW
EXECUTE FUNCTION trg_apply_coupon();

-- Taxes
CREATE TABLE tax (
    tax_id    BIGSERIAL PRIMARY KEY,
    country   VARCHAR(100) NOT NULL,
    state     VARCHAR(100),
    tax_rate  NUMERIC(5,2) NOT NULL CHECK (tax_rate >= 0 AND tax_rate <= 100),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (country, state)
);


-- Payments for orders
CREATE TABLE payment_transaction (
    payment_id    BIGSERIAL PRIMARY KEY,
    order_id      BIGINT NOT NULL
                  REFERENCES customer_order(order_id)
                  ON DELETE CASCADE,
    amount        NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    payment_date  TIMESTAMPTZ NOT NULL DEFAULT now(),
    payment_status payment_status_enum NOT NULL DEFAULT 'pending'
);
CREATE INDEX idx_payment_order ON payment_transaction(order_id);


-- Log of wallet operations
CREATE TABLE wallet_transaction (
    wallet_tx_id    BIGSERIAL PRIMARY KEY,
    wallet_id       BIGINT NOT NULL
                    REFERENCES wallet(wallet_id)
                    ON DELETE CASCADE,
    tx_type         wallet_tx_type_enum NOT NULL,
    amount          NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    payment_id      BIGINT
                    REFERENCES payment_transaction(payment_id)
                    ON UPDATE CASCADE
                    ON DELETE SET NULL,
    tx_time         TIMESTAMPTZ NOT NULL DEFAULT now(),
    status          wallet_tx_status_enum NOT NULL DEFAULT 'pending',
    description     TEXT
);
CREATE INDEX idx_wallet_tx_wallet ON wallet_transaction(wallet_id);


-- Shipping
CREATE TABLE shipping (
    shipping_id         BIGSERIAL PRIMARY KEY,
    order_id            BIGINT NOT NULL
                        REFERENCES customer_order(order_id)
                        ON DELETE CASCADE,
    shipping_address_id BIGINT NOT NULL
                        REFERENCES address(address_id)
                        ON DELETE RESTRICT,
    shipping_method     VARCHAR(60),
    shipping_cost       NUMERIC(10,2) CHECK (shipping_cost >= 0),
    shipping_date       TIMESTAMPTZ,
    delivery_date       TIMESTAMPTZ,
    tracking_number     VARCHAR(120),
    shipping_status     shipping_status_enum NOT NULL DEFAULT 'pending'
);
CREATE INDEX idx_shipping_order ON shipping(order_id);


-- Viewed Items
CREATE TABLE viewed_items (
    viewed_item_id BIGSERIAL PRIMARY KEY,
    user_id        BIGINT NOT NULL
                   REFERENCES user_account(user_id)
                   ON DELETE CASCADE,
    item_id        BIGINT REFERENCES item(item_id)
                   ON DELETE SET NULL,
    save_date      TIMESTAMPTZ NOT NULL DEFAULT now()
);
