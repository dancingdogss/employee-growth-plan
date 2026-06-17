# Known Working Flow

Local server:

py -m http.server 5500

Owner page:

http://localhost:5500/owner.html

Employee page:

http://localhost:5500/index.html

Working test already confirmed:

1. Owner creates employee.
2. Owner adds stock unit.
3. Stock appears once in owner ledger.
4. Stock appears in employee index page.
5. Owner approves/marks sold with Order ID.
6. Employee index sees sold_approved.
7. Progress updates correctly.

Do not break this.