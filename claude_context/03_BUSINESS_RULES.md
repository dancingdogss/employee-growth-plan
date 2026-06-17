# Business Rules

Capital and earnings:

- Each stock unit lent = 300 coins capital.
- 300 coins is not employee salary.
- Each sold_approved unit generates 100 coins earnings.

Splits:

Units 1–20:
- 75 deposit
- 25 salary

Units 21–45:
- 60 deposit
- 40 salary

Units 46+:
- 50 deposit
- 50 salary

Capacity:

- Every 300 deposit = approximately +1 future stock unit capacity.

Counting rules:

Only stock_units with status = sold_approved count toward:
- approved units sold
- deposit
- salary
- earnings
- current level
- capacity unlocked
- weekly stats

employee_seen_at does not affect money calculations.
It only confirms the employee saw the sold update.

Order ID rule:

- order_id is null/empty when a stock unit is created.
- order_id is required only when owner marks the stock as sold.