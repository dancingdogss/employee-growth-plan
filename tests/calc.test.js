'use strict';
// Lightweight test suite — runs with `node --test`, no framework to install.
const test = require('node:test');
const assert = require('node:assert/strict');

const GrowthCalculations = require('../js/calculations.js');
const {
  DEPOSIT_CAP,
  POST_CAP_SALARY_PER_SALE,
  filterAndSortApproved,
  calcApprovedBreakdown,
  calcAvailableSalary,
  calcFinancialTotals,
  calcLevel,
  calcAllEmployeesBreakdown
} = GrowthCalculations;

// Build `n` chronological approved sales for one employee.
function makeApproved(n, opts) {
  opts = opts || {};
  const employeeId = opts.employeeId || 'emp-1';
  const startDate = opts.startDate ? new Date(opts.startDate) : new Date('2026-01-01T00:00:00Z');
  const idPrefix = opts.idPrefix || employeeId;
  const units = [];
  for (let i = 0; i < n; i++) {
    const d = new Date(startDate.getTime() + i * 3600 * 1000);
    units.push({
      id: idPrefix + '-' + i,
      employee_id: employeeId,
      status: 'sold_approved',
      approved_at: d.toISOString(),
      earnings_per_approved_sale: 100
    });
  }
  return units;
}

test('constants match spec', () => {
  assert.equal(DEPOSIT_CAP, 3000);
  assert.equal(POST_CAP_SALARY_PER_SALE, 50);
});

// ── Required approved-sale counts: 0, 20, 21, 45, 46, 47, 60 ──────────────
const EXPECTED = {
  0:  { dep: 0,    sal: 0 },
  20: { dep: 1500, sal: 500 },
  21: { dep: 1560, sal: 540 },
  45: { dep: 3000, sal: 1500 },
  46: { dep: 3000, sal: 1550 },
  47: { dep: 3000, sal: 1600 },
  60: { dep: 3000, sal: 2250 },
};
for (const n of Object.keys(EXPECTED)) {
  const exp = EXPECTED[n];
  test(`${n} ordinary approved sales => deposit ${exp.dep}, salary ${exp.sal}`, () => {
    const r = calcApprovedBreakdown(makeApproved(Number(n)));
    assert.equal(r.count, Number(n));
    assert.equal(r.dep, exp.dep);
    assert.equal(r.sal, exp.sal);
  });
}

test('waiting / issue / cancelled / sale_reported records do not count', () => {
  const approved = makeApproved(5);
  const noise = ['waiting_to_be_sold', 'sale_reported', 'issue', 'cancelled'].map((status, i) => ({
    id: 'noise-' + i,
    employee_id: 'emp-1',
    status,
    approved_at: new Date('2026-01-02T00:00:00Z').toISOString(),
    earnings_per_approved_sale: 100
  }));
  const withApproved = calcApprovedBreakdown(approved);
  const withNoise = calcApprovedBreakdown(approved.concat(noise));
  assert.equal(withNoise.dep, withApproved.dep);
  assert.equal(withNoise.sal, withApproved.sal);
  assert.equal(withNoise.count, 5);
});

test('two employees are calculated independently', () => {
  const empA = makeApproved(46, { employeeId: 'A' });
  const empB = makeApproved(20, { employeeId: 'B' });
  const mixed = empA.concat(empB);
  const all = calcAllEmployeesBreakdown(mixed);
  const a = all.perEmployee.get('A');
  const b = all.perEmployee.get('B');
  assert.equal(a.dep, 3000);
  assert.equal(a.sal, 1550);
  assert.equal(b.dep, 1500);
  assert.equal(b.sal, 500);
});

test('sorting does not mutate the source array or its order', () => {
  // Deliberately out-of-order source.
  const units = makeApproved(4).reverse();
  const before = units.map(u => u.id);
  const sorted = filterAndSortApproved(units);
  // Source untouched...
  assert.deepEqual(units.map(u => u.id), before);
  // ...and a genuinely new array was returned.
  assert.notEqual(sorted, units);
  // ...sorted chronologically ascending.
  assert.deepEqual(sorted.map(u => u.id), ['emp-1-0', 'emp-1-1', 'emp-1-2', 'emp-1-3']);
  // calcApprovedBreakdown must also leave the source untouched.
  const beforeBreakdown = units.map(u => u.id);
  calcApprovedBreakdown(units);
  assert.deepEqual(units.map(u => u.id), beforeBreakdown);
});

test('payouts never change deposit — only available salary', () => {
  const r = calcApprovedBreakdown(makeApproved(46));
  const avail = calcAvailableSalary(r.sal, 200);
  assert.equal(r.dep, 3000);          // deposit untouched by payout
  assert.equal(avail, r.sal - 200);
});

test('negative salary availability from an advance payout still works', () => {
  const totals = calcFinancialTotals(makeApproved(20), { payouts: 1000 });
  // Earned 500 salary, paid 1000 in advance => -500 available.
  assert.equal(totals.salaryEarned, 500);
  assert.equal(totals.salaryPaid, 1000);
  assert.equal(totals.salaryAvailable, -500);
  assert.equal(totals.deposit, 1500); // deposit unaffected by the advance
});

test('owner and employee call the SAME exported function (calcFinancialTotals)', () => {
  assert.equal(typeof calcFinancialTotals, 'function');
  const empUnits = makeApproved(46, { employeeId: 'A' });

  // Employee page: passes its own already-single-employee unit list.
  const employeeResult = calcFinancialTotals(empUnits, { payouts: [{ amount: 300 }] });

  // Owner page: filters the global stock down to one employee, then calls the
  // very same function.
  const globalStock = empUnits.concat(makeApproved(10, { employeeId: 'B' }));
  const ownerResult = calcFinancialTotals(
    globalStock.filter(u => u.employee_id === 'A'),
    { payouts: [{ amount: 300, employee_id: 'A' }] }
  );

  assert.deepEqual(ownerResult, employeeResult);
  assert.equal(ownerResult.deposit, 3000);
  assert.equal(ownerResult.salaryEarned, 1550);
  assert.equal(ownerResult.salaryAvailable, 1250);
});

test('deposit never exceeds 3000 for any approved count 0..80', () => {
  for (let n = 0; n <= 80; n++) {
    const r = calcApprovedBreakdown(makeApproved(n));
    assert.ok(r.dep <= DEPOSIT_CAP, `dep=${r.dep} exceeded cap at n=${n}`);
  }
});

test('a weekly sale after the cap adds 0 deposit and 50 salary', () => {
  // 46 approved sales for one employee; the 46th is "this week's" sale.
  const units = makeApproved(46, { employeeId: 'A' });
  const all = calcAllEmployeesBreakdown(units);
  const lastUnit = units[units.length - 1];
  const contribution = all.perUnit.get(lastUnit.id);
  assert.equal(contribution.d, 0);
  assert.equal(contribution.s, 50);
});

test('calcFinancialTotals reports the full totals set', () => {
  const totals = calcFinancialTotals(makeApproved(21), { payouts: 40 });
  assert.deepEqual(totals, {
    approvedSaleCount: 21,
    totalEarnings: 2100,
    deposit: 1560,
    salaryEarned: 540,
    salaryPaid: 40,
    salaryAvailable: 500
  });
});

test('calcLevel follows the existing progression rules', () => {
  assert.equal(calcLevel(0).lvlNum, 1);
  assert.equal(calcLevel(0).dPct, 75);
  assert.equal(calcLevel(20).lvlNum, 2);
  assert.equal(calcLevel(20).dPct, 60);
  assert.equal(calcLevel(45).lvlNum, 3);
  assert.equal(calcLevel(45).dPct, 50);
  assert.equal(calcLevel(70).lvlNum, 4);      // 45 + 25
  // Max level clamps and reports as full.
  const maxed = calcLevel(10000);
  assert.equal(maxed.lvlNum, 60);
  assert.equal(maxed.pbFull, true);
  assert.equal(maxed.pbW, 100);
});
