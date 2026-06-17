# Employee Stock Tracker — Project Brief

This project is a real-time stock tracking system using:

- index.html = Employee interface
- owner.html = Owner dashboard
- Supabase = shared source of truth
- schema.sql = database structure
- supabase-config.js = local config with URL, anon key, owner PIN, default employee code

The goal is to track stock units assigned to an employee.

Business flow:

1. Employee deposits a stock unit and sends owner the easybox/location photo manually.
2. Owner creates a Stock Unit in owner.html.
3. Stock Unit receives a STOCK ID.
4. ORDER ID does not exist at creation time.
5. ORDER ID appears only when owner sees the unit has sold.
6. Owner marks the Stock Unit as sold and enters ORDER ID + sold_at.
7. Employee sees that Stock Unit was marked as sold.
8. Employee clicks “Mark as seen” to confirm they saw the update.
9. Only sold_approved stock units count toward units sold, deposit, salary, capacity, and weekly stats.
10. Later we will add photo storage by STOCK ID.

The employee must not be able to mark something as sold.
Only the owner controls sold status.