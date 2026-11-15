# Accounting Reports — Stage 1 Design

Date: 2026-11-11
Status: Implemented (SQL awaiting run in Supabase)

## 1. Goal

Give the accountant the three tools they use every day, built on the
accounts and journal tables that already exist:

1. **Post** journal entries (lock a finished draft so it counts in the books).
2. **General Ledger** — every posted movement of one account with a running balance.
3. **Trial Balance** — every account's balance on a date; total debits must equal total credits.
4. **Accounting KPIs on Finance Home** — cash, revenue, expenses, net profit, drafts waiting.

Out of scope for this stage (later stages): invoices, payments, customers/vendors,
aging, P&L / Balance Sheet statements, bank reconciliation, period closing,
reversing entries, PDF/Excel export, multi-currency.

### Success criteria

- An accountant posts a balanced draft; it immediately appears in the ledger of
  every account it touches, with a correct running balance.
- Trial Balance total debit = total credit for any date.
- Finance Home KPIs agree with the Trial Balance numbers for the same period.
- A posted entry can no longer be changed.
- Only active `admin`, `accountant`, `finance_manager` users of the same tenant
  can post or read reports.

## 2. Accounting rules used (plain-language)

These are standard double-entry rules; the system applies them automatically.

| Account type | Normal side | Balance shown as |
|---|---|---|
| asset, expense | Debit | debit − credit |
| liability, equity, income | Credit | credit − debit |

- A balance on its normal side is shown as a positive number. A balance on the
  wrong side (e.g. a bank account overdrawn) is shown in parentheses, e.g. `(1,250.00)`.
- **Only posted entries count** in every report and KPI. Drafts are ignored.
- **Posting is final.** A posted entry cannot be edited or deleted. Mistakes are
  fixed later with a reversing entry (future stage).
- Posting requires: status `draft`, at least 2 lines, total debit = total credit,
  all accounts still active.
- **Cash balance** = sum of balances of asset accounts flagged *Cash/Bank*, up to today.
- **Revenue** (month) = income accounts, credit − debit, for posted entries dated in that month.
- **Expenses** (month) = expense accounts, debit − credit, same month.
- **Net profit** = Revenue − Expenses.

## 3. Database changes (Supabase)

New script: `supabase/install_accounting_reports.sql` (run once, transactional,
idempotent — same style as `install_accounting_workspace.sql`).

### 3.1 Schema

```sql
alter table public.accounts add column if not exists is_cash boolean not null default false;
alter table public.journal_entries add column if not exists posted_at timestamptz;
alter table public.journal_entries add column if not exists posted_by uuid references public.users(id);
create index if not exists idx_journal_lines_tenant_account on public.journal_lines (tenant_id, account_id);
create index if not exists idx_journal_entries_tenant_status_date on public.journal_entries (tenant_id, status, entry_date);
```

### 3.2 Functions

All functions: `security definer`, `set search_path = public, pg_temp`, resolve
tenant from `auth.uid()` and require role in `('admin','accountant','finance_manager')`
and `is_active`, exactly like `accounting_save_draft`. Execute granted to
`authenticated` only.

| Function | Purpose |
|---|---|
| `accounting_save_account(p_id, p_code, p_name, p_type, p_is_active, p_is_cash)` | Replaces the 5-arg version (old one dropped). `p_is_cash` must be false unless `p_type = 'asset'`. |
| `accounting_post_entry(p_id uuid) returns void` | Locks the entry row, validates the posting rules in §2, sets `status='posted'`, `posted_at=now()`, `posted_by=auth.uid()`. Posting an already-posted entry is a no-op (safe to retry). |
| `accounting_ledger(p_account_id uuid, p_from date, p_to date) returns jsonb` | `{account:{id,code,name,type}, opening, closing, truncated, rows:[{entry_id, entry_date, memo, debit, credit, balance}]}`. Opening = balance of posted lines before `p_from`. Rows ordered by `entry_date, created_at, entry id`; running balance computed with a window function in the account's normal direction. Max 2000 rows; `truncated=true` tells the UI to ask for a shorter range. |
| `accounting_trial_balance(p_as_of date) returns table(account_id, code, name, type, debit, credit)` | One row per account with posted activity up to `p_as_of`. Net = Σdebit − Σcredit; `debit = greatest(net,0)`, `credit = greatest(-net,0)`. Ordered by code. |
| `accounting_kpis(p_month date) returns jsonb` | `{cash_balance, has_cash_accounts, revenue, expenses, net_profit, draft_count, stale_draft_count}`. Month = the calendar month containing `p_month`. `stale_draft_count` = drafts older than 7 days. |

The existing `accounting_save_draft` already refuses to change a non-draft
entry, so posted entries are protected without further changes.

### 3.3 SQL tests

`supabase/test_accounting_reports.sql` (same style as `test_hr_form_drafts.sql`),
run inside a rolled-back transaction:

- posting an unbalanced / single-line / inactive-account entry fails;
- posting twice is a no-op; posted entry cannot be re-saved as draft;
- ledger opening + rows + closing are consistent; running balance sign follows the normal side;
- trial balance debits = credits;
- KPIs match hand-calculated values; drafts are excluded;
- a user of another tenant / role `employee` gets `42501`.

## 4. Flutter changes

Follows the existing accounting structure (`domain/models`, `domain/repos`,
`data/repos/*_impl.dart`, `view/cubit`, `view/pages|sections|widgets`) and the
bilingual `accountingText(context, ar, en)` helper.

### 4.1 Chart of Accounts (existing)

- `Account` model gains `isCash`.
- Account form dialog: a **"Cash / Bank account"** checkbox, visible only when
  type is `asset` (cleared automatically if type changes).
- Accounts table: small "Cash" chip on flagged accounts; row action
  **"View ledger"** → opens General Ledger for that account.

### 4.2 Journal (existing)

- `JournalRepo.postEntry(String id)` → `accounting_post_entry`.
- Draft rows get a **Post** action. Confirmation dialog:
  *"Posting is final. The entry will count in the books and can no longer be edited."*
- Status chip: Draft (amber) / Posted (green). After posting the list refreshes.

### 4.3 General Ledger (new) — `lib/features/accounting/ledger/`

- Route `/ledger?account=<id>` (`AppRoutes.ledger`).
- Top bar: searchable account picker (active + inactive accounts), date range
  (default: first day of current month → today), Refresh.
- Summary cards: Opening balance · Total debit · Total credit · Closing balance.
- Table: Date · Memo · Debit · Credit · Balance. Opening balance as the first row.
- Empty state when no account selected / no movements. Banner when `truncated`.
- `LedgerCubit` states: initial (no account) / loading / loaded / error.

### 4.4 Trial Balance (new) — `lib/features/accounting/trial_balance/`

- Route `/trial-balance` (`AppRoutes.trialBalance`).
- Top bar: "As of" date (default today), "Hide zero balances" switch (default on), Refresh.
- Table grouped by type (Assets, Liabilities, Equity, Income, Expenses):
  Code · Account · Debit · Credit. Footer totals.
- Status badge: **Balanced** (green) or **Out of balance by X** (red — should
  never happen; signals a data problem).
- Tapping a row opens the ledger for that account, date range = start of year → as-of date.

### 4.5 Finance Home KPIs (existing page)

- New widget `finance_accounting_kpis.dart` at the top of `FinanceHomePage`,
  above the payroll sections, with a month selector (default current month).
- Five cards: Cash balance · Revenue · Expenses · Net profit (green/red) · Drafts to post.
- Alerts row: "N drafts older than 7 days are waiting to be posted" (→ Journal);
  "No cash accounts marked yet" (→ Chart of Accounts) when `has_cash_accounts=false`.
- Quick links: General Ledger, Trial Balance.
- Data via new `AccountingReportsRepo.fetchKpis(month)`; KPI errors show an
  inline retry and never break the payroll sections.

### 4.6 Shared reports repo & navigation

- `lib/features/accounting/reports/` — `AccountingReportsRepo` (+ impl) with
  `fetchLedger`, `fetchTrialBalance`, `fetchKpis`; models `LedgerReport`,
  `LedgerRow`, `TrialBalanceRow`, `AccountingKpis`. Registered in `AppDI`.
- Nav items in `nav_menu_items_part.dart` under the Accounting section, roles
  `admin, accountant, finance_manager`: **General Ledger**, **Trial Balance**.
  Labels and section mapping added in `nav_i18n.dart`.
- Routes added in `app_routes.dart` and `app_router_shell_routes_part.dart`.

### 4.7 Money formatting

One helper `formatMoney(num)` → 2 decimals with thousands separators;
negative (abnormal) balances in parentheses. Amounts are right-aligned.

## 5. Error handling

- Postgres errors mapped to bilingual messages: `42501` → "You don't have
  permission"; "Debits must equal credits" → "Entry is not balanced";
  inactive account → "Entry uses an inactive account"; anything else → generic
  message + retry.
- All report pages show loading, empty, and error-with-retry states.

## 6. Testing

- SQL: `test_accounting_reports.sql` (§3.3).
- Dart unit tests: model `fromMap` parsing (numbers as int/double/string),
  `formatMoney`, `LedgerCubit` / `TrialBalanceCubit` state transitions with a fake repo,
  journal post flow in `JournalCubit`.
- Widget tests: trial balance totals + Balanced badge; Post confirmation dialog.
- Manual check: create accounts (one Cash), post 3 entries, compare ledger,
  trial balance and KPIs by hand; run in Arabic and English (RTL).

## 7. Rollout order

1. SQL install script + SQL tests.
2. Account `isCash` + Journal **Post** action.
3. Reports repo + General Ledger.
4. Trial Balance.
5. Finance Home KPIs + navigation.
