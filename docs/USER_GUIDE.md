# Employee Progress Tracker – Documentation Pack

This documentation pack contains two guides:

1. **User Guide** – send this to the employee/player so he knows how to use the tracker.
2. **Owner / Implementation Notes** – keep this for yourself so you know how to maintain, publish, and update the tracker.

---

# Employee Progress Tracker – User Guide

## What this page is

This page helps you track your progress in the stock/deposit/salary plan.

You can use it to see:

- how many units you sold
- your current level
- your current split
- your deposit balance
- your salary balance
- how much future stock capacity you unlocked
- how many units remain until the next level

The tracker works on both phone and desktop.

---

## The basic idea

Each stock unit has two different values:

### 1. Capital lent

Each stock unit given to you represents:

```text
300 coins of stock value
```

This is not salary.  
This is the value of the stock being trusted to you.

### 2. Earnings generated

When you sell 1 stock unit, it generates:

```text
100 coins of growth value
```

That 100 coins is split into:

```text
Deposit balance + Salary balance
```

---

## Deposit vs salary

### Deposit balance

Deposit balance is used to grow future stock capacity.

Simple rule:

```text
Every 300 deposit coins = about +1 extra stock unit capacity
```

Examples:

```text
750 deposit = about +2.5 units capacity
1,500 deposit = about +5 units capacity
3,000 deposit = about +10 units capacity
```

### Salary balance

Salary balance is the part you can use or withdraw.

The higher your level becomes, the better your salary split becomes.

---

## Levels and splits

## Level 1 – Start

Deposit range:

```text
0 → 1,500 deposit
```

Split:

```text
75 deposit / 25 salary
```

This means every unit sold gives:

```text
+75 deposit
+25 salary
```

First target:

```text
20 units sold
```

At 20 units sold:

```text
Deposit: 1,500
Salary: 500
Level 2 unlocked
```

---

## Level 2 – Growth

Deposit range:

```text
1,500 → 3,000 deposit
```

Split:

```text
60 deposit / 40 salary
```

This means every unit sold gives:

```text
+60 deposit
+40 salary
```

At 45 total units sold:

```text
Deposit: 3,000
Salary: 1,500
Level 3 unlocked
```

---

## Level 3 – Stable

Deposit range:

```text
3,000+ deposit
```

Split:

```text
50 deposit / 50 salary
```

This is the long-term stable split.

Every unit sold gives:

```text
+50 deposit
+50 salary
```

---

## How to use the tracker

## 1. Open the link

Open the tracker link in Chrome, Safari, or another normal browser.

It works on:

- phone
- desktop
- tablet

For best results on phone, open it in Chrome or Safari.

---

## 2. Enter units sold

In the section called **Your current progress**, use the buttons:

```text
+1
-1
+5
+10
-5
Reset
```

Use them to update the number of units you sold so far.

Example:

If you sold 10 units, press `+10`.

---

## 3. Read your current status

The tracker automatically shows:

- Current level
- Current split
- Deposit balance
- Salary balance
- Capital represented
- Earnings generated
- Capacity unlocked
- Next milestone

Example after 10 units:

```text
Deposit: 750
Salary: 250
Capacity unlocked: +2.5 units
Current level: Level 1
Current split: 75 / 25
```

---

## 4. Follow the progress bar

The XP-style bar shows how close you are to the next level.

If you are below 20 units:

```text
Progress to Level 2
```

If you are between 20 and 45 units:

```text
Progress to Level 3
```

If you are above 45 units:

```text
Level 3 unlocked
```

---

## 5. Use the milestone checklist

The checklist marks goals as completed automatically.

Milestones:

```text
10 units sold
20 units sold / Level 2 unlocked
30 units sold
45 units sold / Level 3 unlocked
```

A milestone is marked complete when your units sold reaches that number.

---

## Saving progress

Your progress is saved automatically on the device and browser you use.

This means:

```text
Same phone + same browser + same link = progress stays saved
```

But progress usually does not sync automatically between desktop and phone.

---

## Moving progress to another device

If you want to move your progress from one device to another:

1. Open the tracker on the first device.
2. Set the correct units sold.
3. Press:

```text
Copy progress link
```

4. Send/open that copied link on the other device.

The copied link will look like:

```text
https://example.github.io/employee-growth-plan/?units=20
```

When opened, it loads the tracker with 20 units already set.

---

## Manual import

If needed, you can also use:

```text
Import from another device
```

Type the number of units sold and press:

```text
Load
```

---

## Important summary

The first target is simple:

```text
Sell 20 units total
Reach 1,500 deposit
Unlock Level 2
```

After Level 2, the split improves.

After 45 total units, Level 3 is unlocked and the split becomes stable:

```text
50 deposit / 50 salary
```


---

# Employee Progress Tracker – Owner / Implementation Notes

## Purpose

This document is for maintaining and updating the Employee Progress Tracker.

The tracker is a single-page HTML app used to explain and track the employee/player growth plan.

It is designed to be:

- simple
- mobile-friendly
- shareable by link
- usable without login
- stored locally on the user's browser
- easy to host on GitHub Pages

---

## Current file

Main app file:

```text
index.html
```

Recommended repo:

```text
employee-growth-plan/
└── index.html
```

Recommended GitHub Pages URL format:

```text
https://YOUR_USERNAME.github.io/employee-growth-plan/
```

---

## Current plan logic

## Stock and earnings rules

Each stock unit lent:

```text
300 coins capital
```

Each unit sold generates:

```text
100 coins growth value
```

That 100 is split between:

```text
Deposit balance + Salary balance
```

Deposit capacity rule:

```text
Every 300 deposit = roughly +1 future stock unit capacity
```

---

## Tier system

### Tier 1

```text
Units 0–20
Split: 75 deposit / 25 salary
```

### Tier 2

```text
Units 21–45
Split: 60 deposit / 40 salary
```

### Tier 3

```text
Units 46+
Split: 50 deposit / 50 salary
```

---

## Important milestones

```text
10 units = 750 deposit / 250 salary / +2.5 capacity
20 units = 1,500 deposit / 500 salary / +5 capacity / Level 2 unlocked
30 units = 2,100 deposit / 900 salary / +7 capacity
45 units = 3,000 deposit / 1,500 salary / +10 capacity / Level 3 unlocked
```

---

## JavaScript behavior

The script stores progress in:

```javascript
localStorage
```

Storage key:

```javascript
emp_tracker_units
```

Progress value:

```text
units sold
```

Example:

```text
emp_tracker_units = 20
```

---

## URL progress feature

The app supports progress transfer through a URL query parameter:

```text
?units=20
```

Example:

```text
https://YOUR_USERNAME.github.io/employee-growth-plan/?units=20
```

Loading order:

1. If `?units=NUMBER` exists, the app uses that value.
2. It then saves that value into localStorage.
3. If no URL value exists, the app loads the value from localStorage.
4. If neither exists, it starts at 0.

This allows progress to move between desktop and phone without a backend.

---

## User-facing buttons

Main tracker buttons:

```text
+1
-1
+5
+10
-5
Reset
Copy progress link
Load
```

Button behavior:

- `+1` adds one unit sold.
- `-1` removes one unit sold, but never below 0.
- `+5` adds five units.
- `+10` adds ten units.
- `-5` removes five units, but never below 0.
- `Reset` resets progress to 0 after confirmation.
- `Copy progress link` copies the current URL with `?units=NUMBER`.
- `Load` loads the manually entered unit count.

---

## Main calculation function

Current calculation logic is inside:

```javascript
calcStats(u)
```

It calculates:

- deposit
- salary
- capacity unlocked
- capital represented
- earnings generated
- current level
- current split
- progress bar state
- next milestone

Core formulas:

```javascript
capital = units * 300
earnings = units * 100
capacity = deposit / 300
```

Tier logic:

```javascript
var t1 = Math.min(u, 20);
dep += t1 * 75;
sal += t1 * 25;

if (u > 20) {
  var t2 = Math.min(u - 20, 25);
  dep += t2 * 60;
  sal += t2 * 40;
}

if (u > 45) {
  var t3 = u - 45;
  dep += t3 * 50;
  sal += t3 * 50;
}
```

---

## How to publish on GitHub Pages

## 1. Create repo

Recommended public repo name:

```text
employee-growth-plan
```

## 2. Folder structure

```text
employee-growth-plan/
└── index.html
```

## 3. Initialize Git

From the `employee-growth-plan` folder:

```bash
git init
git add index.html
git commit -m "Add employee growth progress tracker"
```

## 4. Connect to GitHub

Replace the URL with your real repo URL:

```bash
git remote add origin https://github.com/YOUR_USERNAME/employee-growth-plan.git
git branch -M main
git push -u origin main
```

## 5. Enable GitHub Pages

On GitHub:

```text
Repository → Settings → Pages
```

Use:

```text
Source: Deploy from a branch
Branch: main
Folder: /root
```

Final link format:

```text
https://YOUR_USERNAME.github.io/employee-growth-plan/
```

---

## How to update the tracker later

Edit:

```text
index.html
```

Then run:

```bash
git add index.html
git commit -m "Update employee tracker"
git push
```

The public link stays the same.

---

## What to tell the employee

Recommended short message:

```text
Open this in Chrome or Safari.

Your progress saves on the device you use.

If you want to move progress to another device, press "Copy progress link" and open that link on the other device.

Best option: add it to your phone home screen so it works almost like an app.
```

---

## Mobile use

Works on mobile.

Best flow:

### iPhone

```text
Open in Safari → Share → Add to Home Screen
```

### Android

```text
Open in Chrome → 3 dots → Add to Home screen
```

---

## Limitations

Current limitations:

- Progress is not stored online.
- Progress does not sync automatically between devices.
- localStorage can be cleared if browser/site data is deleted.
- No login system.
- No backend.
- No database.
- Anyone with the link can open the tracker.

This is intentional for the current lightweight version.

---

## Future improvements

Possible next steps:

### Simple improvements

- Add employee name field.
- Add date started.
- Add notes section.
- Add batch history.
- Add manual “batch completed” logs.
- Add export progress as text/JSON.
- Add import progress from JSON.

### Medium improvements

- Add password/PIN screen.
- Add multiple employee profiles on same page.
- Add automatic weekly view.
- Add a “payment due” field.
- Add admin-only hidden settings.

### Advanced improvements

- Add Firebase/Supabase backend.
- Save progress online.
- Sync progress across devices.
- Add login.
- Add admin dashboard.
- Connect to Telegram bot later.

---

## Implementation order for future updates

When continuing development, use this order:

1. Make sure the current HTML works locally.
2. Add only one feature at a time.
3. Test on desktop.
4. Test on mobile width.
5. Test localStorage after refresh.
6. Test progress link with `?units=NUMBER`.
7. Commit and push.
8. Open GitHub Pages link and verify the live version.

Recommended commit style:

```bash
git commit -m "Add employee name field"
git commit -m "Improve progress tracker mobile layout"
git commit -m "Add batch history section"
```
