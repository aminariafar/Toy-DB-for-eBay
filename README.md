# 🛒 Toy Database for eBay-like Marketplace

This project implements a **mock e-commerce database** modeled after platforms like eBay.  
It captures the core entities and workflows of an online marketplace using a relational database schema, enriched with sample data and demonstration queries.

---

## ✨ Key Contents

### Schema (`creation.sql`)
- Custom **ENUM types** for consistent states:  
  - Item condition (`new`, `used`, `refurbished`, `other`)  
  - Item status (`draft`, `active`, `ended`, `sold`, `cancelled`)  
  - Payment, shipping, order, and message statuses  
  - Wallet transaction types & statuses  
- Core tables include:  
  - **`user_account`** — buyers & sellers with profiles and ratings  
  - **`category`** — hierarchical product categories  
  - **`item`** — listed products with status and condition  
  - **`order`**, **`payment`**, **`shipping`** — transaction workflows  
  - **`wallet`**, **`wallet_transaction`** — simple e-wallet functionality  
  - **`message`** — private messages between users  
  - **`cart`** — shopping cart linked to users  

### Sample Data (`data.sql`)
- Pre-populated categories: *Digital Goods*, *Mobile Phones*, *Laptops*, *Fashion & Apparel*, *Books*  
- Example users: multiple **sellers and buyers** with realistic names, emails, and ratings  
- Sample listings, transactions, and user activity covering end-to-end flows  

### Demonstration Queries (`queries.sql`)
- **Data quality checks** (e.g., total users, sellers with draft items)  
- **Marketplace insights**:  
  - Items per category (ranked)  
  - Active listings by seller  
  - Transaction and order summaries  

---

## 🧱 Project Structure
```
Toy-DB-for-eBay-main/
├── creation.sql   # Defines schema, tables, and enums
├── data.sql       # Inserts categories, users, items, transactions
└── queries.sql    # Demonstration queries for analysis
```

---

## 🎯 Context
This project demonstrates how relational database design can model the workflows of an **online marketplace**:  
- Buyers and sellers interact through listings, orders, and messages  
- Transactions progress through statuses for payment, shipping, and delivery  
- Categories and conditions classify items  
- Wallet transactions track payments and refunds  

It serves as a **teaching example** for both **SQL schema design** and **mock e-commerce system modeling**.

---

📚 Made for research & learning — modeling how a marketplace like eBay could be represented in a relational database.
