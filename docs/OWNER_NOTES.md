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
