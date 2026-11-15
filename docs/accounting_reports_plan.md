# Accounting Reports (Stage 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add journal posting, General Ledger, Trial Balance and accounting KPIs on Finance Home.

**Architecture:** New `security definer` Postgres functions compute posting and reports server-side
(same guard pattern as `accounting_save_draft`). Flutter calls them through repos; new pages follow the
existing accounting structure (`domain/`, `data/repos/`, `view/`) and the shared `accounting_ui.dart`
helpers. Finance Home gets a self-contained KPI widget with its own repo.

**Tech Stack:** Flutter, flutter_bloc (Cubit), go_router, supabase_flutter, Postgres (Supabase), flutter_test.

**Spec:** `docs/accounting_reports_design.md`

## Global Constraints

- Allowed roles everywhere: active users with role in `('admin','accountant','finance_manager')`, same tenant; otherwise errcode `42501`.
- Reports and KPIs count `journal_entries.status = 'posted'` only.
- Normal side: `asset`, `expense` → debit − credit; `liability`, `equity`, `income` → credit − debit. Abnormal (negative) balances display in parentheses, e.g. `(1,250.00)`.
- All UI text via `accountingText(context, ar, en)` (Arabic + English). Amounts and dates rendered with `textDirection: TextDirection.ltr`.
- Money: 2 decimals, thousands separators — build on existing `payrollMoney` (`lib/features/payroll/view/widgets/payroll_format.dart`).
- Panels/tables use `accountingPanel`, `AccountingTable`, `accountingBadge`, `accountingHeading` from `lib/features/accounting/view/accounting_ui.dart`.
- SQL scripts are run by the user in the Supabase SQL Editor (do not run against the remote DB from the agent).
- **No git commits** — the working tree has the user's own uncommitted work in the same files. The user commits at the end.
- After every Dart change: `flutter analyze` on touched paths must report no issues.

## Review Focus

1. **Brand-new tenant with no posted entries** → ledger, trial balance and KPIs show zeros / empty states, never an exception. (Tests in Tasks 4, 5, 6, 7.)
2. **Numeric values arriving as `int`, `double` or `String`** from PostgREST/jsonb → parsed correctly. (`_num` helper test in Task 4.)
3. **Double-clicking Post / retrying after a network error** → entry posted once, button disabled while busy, second call is a server no-op. (Tasks 1 and 3.)
4. **Ledger "from" date after "to" date** → UI cannot pick it; SQL raises `Invalid date range`. (Tasks 1 and 5.)
5. **Inactive accounts** with history still appear in the ledger picker and trial balance. (Tasks 1 and 5.)

---

## File Map

| File | Status | Responsibility |
|---|---|---|
| `supabase/install_accounting_reports.sql` | create | schema changes + 5 functions |
| `supabase/test_accounting_reports.sql` | create | rolled-back SQL assertions |
| `lib/features/accounting/view/accounting_ui.dart` | modify | `accountingBalance()`, `accountingErrorText()` |
| `lib/features/accounting/accounts/domain/models/account.dart` | modify | `isCash` |
| `lib/features/accounting/accounts/domain/repos/accounts_repo.dart` + `data/repos/accounts_repo_impl.dart` | modify | `isCash` param, select `is_cash` |
| `lib/features/accounting/accounts/view/widgets/accounts_workspace.dart` | modify | checkbox, Cash chip, View-ledger action |
| `lib/features/accounting/journal/domain/repos/journal_repo.dart` + impl | modify | `postEntry` |
| `lib/features/accounting/journal/view/cubit/journal_cubit.dart` | modify | `postEntry` |
| `lib/features/accounting/journal/view/widgets/journal_table.dart` + `sections/journal_table_section.dart` | modify | Post action + confirm dialog |
| `lib/features/accounting/reports/domain/accounting_reports_models.dart` | create | `LedgerReport`, `LedgerRow`, `TrialBalanceRow`, `AccountingKpis` |
| `lib/features/accounting/reports/domain/accounting_reports_repo.dart` | create | abstract repo |
| `lib/features/accounting/reports/data/accounting_reports_repo_impl.dart` | create | RPC calls |
| `lib/features/accounting/ledger/view/ledger_cubit.dart`, `ledger_page.dart` | create | General Ledger |
| `lib/features/accounting/trial_balance/view/trial_balance_cubit.dart`, `trial_balance_page.dart` | create | Trial Balance |
| `lib/features/finance_home/finance_accounting_kpis.dart` | create | KPI strip widget |
| `lib/features/finance_home/finance_home_page.dart` | modify | mount KPI strip |
| `lib/core/di/app_di.dart`, `lib/core/routing/app_routes.dart`, `app_router.dart`, `app_router_shell_routes_part.dart`, `lib/features/shell/domain/nav_menu_items_part.dart`, `nav_i18n.dart` | modify | DI, routes, menu |
| `test/accounting_reports_*_test.dart` | create | tests per task |

---

### Task 1: Database script (schema + functions + SQL tests)

**Files:**
- Create: `supabase/install_accounting_reports.sql`
- Create: `supabase/test_accounting_reports.sql`

**Interfaces — Produces (RPC contract used by Tasks 2–7):**
- `accounting_save_account(p_id uuid, p_code text, p_name text, p_type text, p_is_active boolean, p_is_cash boolean) returns uuid`
- `accounting_post_entry(p_id uuid) returns void`
- `accounting_ledger(p_account_id uuid, p_from date, p_to date) returns jsonb` →
  `{"account":{"id","code","name","type"},"opening":n,"total_debit":n,"total_credit":n,"closing":n,"truncated":bool,"rows":[{"entry_id","entry_date","memo","debit","credit","balance"}]}`
- `accounting_trial_balance(p_as_of date) returns table(account_id uuid, code text, name text, type text, debit numeric, credit numeric)`
- `accounting_kpis(p_month date) returns jsonb` →
  `{"cash_balance","has_cash_accounts","revenue","expenses","net_profit","draft_count","stale_draft_count"}`

- [ ] **Step 1: Write `test_accounting_reports.sql`** (style of `supabase/test_hr_form_drafts.sql`: `begin; … rollback;`, `set local role authenticated; set local request.jwt.claims …` to impersonate, `do $$ … assert … $$`). Seed one tenant, an `accountant` user, an `employee` user, a second-tenant accountant, accounts `1100 Bank (asset, is_cash)`, `2100 Payables (liability)`, `4100 Sales (income)`, `5100 Salaries (expense)`, `5900 Old (expense, inactive later)`. Assertions:
  - posting entry with total_debit ≠ total_credit (inserted directly) raises `Debits must equal credits`;
  - posting entry with 1 line raises `Entry requires at least 2 lines`;
  - posting entry whose account became inactive raises `Entry uses an inactive account`;
  - post valid entry E1 (2026-10-05: Dr Bank 1000 / Cr Sales 1000) → status `posted`, `posted_at`/`posted_by` set; posting E1 again succeeds and `posted_at` unchanged;
  - `accounting_save_draft` with E1's id and different values raises;
  - post E2 (2026-10-20: Dr Salaries 400 / Cr Bank 400); keep D1 draft (Dr Salaries 50 / Cr Bank 50);
  - `accounting_ledger(Bank, '2026-10-10', '2026-10-31')` → opening 1000, one row balance 600, closing 600, total_credit 400;
  - `accounting_ledger(Sales, '2026-10-01','2026-10-31')` → row balance 1000 (credit-normal positive);
  - `accounting_ledger(Bank, '2026-11-01', '2026-10-01')` raises `Invalid date range`;
  - `accounting_trial_balance('2026-10-31')`: sum(debit) = sum(credit) = 1400; Bank debit 600; Old account (inactive, posted history if seeded) still listed;
  - `accounting_kpis('2026-10-15')` → revenue 1000, expenses 400, net_profit 600, cash_balance 600, draft_count 1, has_cash_accounts true;
  - `accounting_save_account` with `p_type='expense', p_is_cash=true` raises `Only asset accounts can be cash`;
  - as `employee` and as other-tenant accountant, each function raises sqlstate `42501` (other-tenant: ledger on a foreign account raises `42501`).

- [ ] **Step 2: Write `install_accounting_reports.sql`** (`begin; … notify pgrst,'reload schema'; commit;`, idempotent):
  - Schema exactly as spec §3.1.
  - `drop function if exists public.accounting_save_account(uuid,text,text,text,boolean);` then re-create with `p_is_cash boolean default false`, same body as the current one plus: `if p_is_cash and p_type <> 'asset' then raise exception 'Only asset accounts can be cash'; end if;` and write `is_cash`.
  - `accounting_post_entry`: guard; `select … for update`; foreign tenant → `42501`; status `posted` → `return`; status ≠ `draft` → `Only drafts can be posted`; count lines < 2 → `Entry requires at least 2 lines`; sum(debit) ≠ sum(credit) or ≠ stored totals → `Debits must equal credits`; any line account not active → `Entry uses an inactive account`; update status/posted_at/posted_by.
  - `accounting_ledger`: guard; account must belong to tenant (`42501`); `p_from > p_to` → `Invalid date range`; `v_sign := case when type in ('asset','expense') then 1 else -1 end`. Opening = `v_sign * sum(debit-credit)` for posted lines with `entry_date < p_from`. Rows from posted lines in range, running balance:
    ```sql
    v_opening + sum(v_sign*(l.debit-l.credit)) over (order by e.entry_date, e.created_at, e.id, l.id rows unbounded preceding)
    ```
    Totals and closing computed over **all** rows in range; `rows` limited to first 2000; `truncated = count > 2000`.
  - `accounting_trial_balance`: guard; group posted lines with `entry_date <= p_as_of` by account; `debit = greatest(sum(debit)-sum(credit),0)`, `credit = greatest(sum(credit)-sum(debit),0)`; order by code.
  - `accounting_kpis`: guard; month range = `date_trunc('month', p_month)` → +1 month; cash = sum over `is_cash` asset accounts of posted (debit−credit) up to `current_date`; revenue/expenses per spec §2; `stale_draft_count` = drafts with `created_at < now() - interval '7 days'`.
  - `revoke all … from public; grant execute … to authenticated;` for all 5 functions.

- [ ] **Step 3: User runs both scripts in the SQL Editor.** Ask the user to run `install_accounting_reports.sql`, then `test_accounting_reports.sql`. Expected: install commits; test finishes with no assertion error (ends in `ROLLBACK`). Do not continue to Task 2's repo-integration checks until confirmed (Dart tasks can proceed in parallel since they use fakes).

---

### Task 2: Cash/Bank flag on accounts

**Files:**
- Modify: `account.dart`, `accounts_repo.dart`, `accounts_repo_impl.dart`, `accounts_workspace.dart`
- Modify: `test/accounting_repo_test.dart`, `test/accounting_workspace_test.dart` (fixture signatures)

**Interfaces — Produces:**
- `Account.isCash` (`bool`, from `map['is_cash'] ?? false`)
- `AccountsRepo.updateAccount({…, required bool isActive, bool isCash = false})`, `createAccount({…, bool isCash = false})`
- `AccountsWorkspace({required AccountsRepo repo, ValueChanged<String>? onOpenLedger})` — called with account id; default `context.go('${AppRoutes.ledger}?account=$id')`. This task adds the constants `AppRoutes.ledger = '/ledger'` and `AppRoutes.trialBalance = '/trial-balance'` to `app_routes.dart`; Tasks 5–6 add the `GoRoute`s.

- [ ] **Step 1: Update failing tests.**
  - In `accounting_repo_test.dart` existing test "Account update uses scoped server operation…": pass `isCash: false` and expect body to include `'p_is_cash': false`. Add test `Cash flag is sent for asset accounts` → `updateAccount(type: 'asset', isCash: true)` body contains `'p_is_cash': true`.
  - In `accounting_workspace_test.dart`: add `isCash` capture to `AccountsFixture.updateAccount`; new test `Cash checkbox only for assets and clears on type change`: open form, select type Asset → `find.byKey(ValueKey('account-is-cash'))` findsOneWidget, tap it, change type to Expense → checkbox gone, save → fixture `isCash == false`. Second test: editing an `isCash` account shows chip text `Cash` in its row; tapping `ValueKey('ledger-account-<id>')` calls `onOpenLedger` with the id.

- [ ] **Step 2:** `flutter test test/accounting_repo_test.dart test/accounting_workspace_test.dart` → FAIL (missing param/keys).

- [ ] **Step 3: Implement.** Add `is_cash` to the repo `select`; send `p_is_cash`. In the workspace: `bool isCash = false` state; `CheckboxListTile(key: ValueKey('account-is-cash'), title: tr('حساب نقدية / بنك','Cash / Bank account'), subtitle: tr('يُحتسب ضمن رصيد النقدية','Counted in the cash balance'))` shown only when `type == 'asset'`; type change to non-asset sets `isCash = false`; `edit()`/`resetForm()` set it. Table: Cash chip via `accountingBadge(tr('نقدية','Cash'))` next to the name; Actions cell becomes a `Row` with the edit button and `IconButton(key: ValueKey('ledger-account-${a.id}'), icon: Icons.receipt_long_outlined, tooltip: tr('عرض دفتر الأستاذ','View ledger'))`.

- [ ] **Step 4:** Re-run the two test files → PASS. `flutter analyze lib/features/accounting test` → no issues.

---

### Task 3: Post journal entries

**Files:**
- Modify: `journal_repo.dart`, `journal_repo_impl.dart`, `journal_cubit.dart`, `journal_table.dart`, `journal_table_section.dart`
- Modify: `test/accounting_repo_test.dart`, `test/accounting_workspace_test.dart` (`JournalFixture` gets `postEntry`)
- Create: `test/accounting_post_entry_test.dart`

**Interfaces — Produces:**
- `JournalRepo.postEntry(String id) → Future<void>` (rpc `accounting_post_entry`, params `{'p_id': id}`)
- `JournalCubit.postEntry(String id) → Future<Object?>` — returns `null` on success (then reloads), or the raw error object; while running, `state.postingId == id` (new nullable field on `JournalState`, cleared after).
- `accountingErrorText(BuildContext context, Object error) → String` in `accounting_ui.dart` (used by every later task).
- `JournalTable({required List<JournalEntry> items, ValueChanged<JournalEntry>? onPost, String? postingId})`

- [ ] **Step 1: Write failing tests.**
  - repo: `Post entry calls accounting_post_entry with id` → path `/rest/v1/rpc/accounting_post_entry`, body `{'p_id': 'entry'}`.
  - `accountingErrorText` (pump a `MaterialApp` with `Locale('en')`, then `Locale('ar')`): `PostgrestException(message:'x', code:'42501')` → `You don't have permission for this action.` / `ليست لديك صلاحية لهذا الإجراء.`; message containing `Debits must equal credits` → `Entry is not balanced.` / `القيد غير متوازن.`; containing `inactive account` → `Entry uses an inactive account.` / `القيد يستخدم حسابًا غير نشط.`; anything else → `AppError.message(e)`.
  - cubit (`accounting_post_entry_test.dart`, fake repo): `postEntry success reloads list and clears postingId`; `postEntry failure returns the error and keeps list`; `second postEntry while one is running is ignored` (fake uses a `Completer`; repo `posts` counter == 1).
  - widget: pump `JournalTableSection` with a cubit over a fake containing one draft and one posted entry → `ValueKey('post-entry-<draftId>')` present, absent for the posted one; tap → dialog with text `Posting is final. The entry will count in the books and can no longer be edited.`; tap `Post` → fake `posts == 1`, snackbar `Entry posted.`; Cancel path → `posts == 0`.

- [ ] **Step 2:** Run the three files → FAIL.

- [ ] **Step 3: Implement.** Repo method; cubit method (guard `if (state.postingId != null) return null;`, catch and return the error); `accountingErrorText` in `accounting_ui.dart` (check `PostgrestException.code == '42501'` first, then substring match on the message). Table: add a 6th column `t.actions`-style heading `tr('إجراء','Action')`, widths `[16,36,14,14,12,8]`; draft rows show `TextButton.icon(key: ValueKey('post-entry-${e.id}'), icon: Icons.task_alt, label: tr('ترحيل','Post'))`, disabled + small spinner when `postingId == e.id`. Posted badge uses `accountingBadge(t.posted, active: true)` and draft `active: false` so they differ visually. Section owns the confirm dialog (`showDialog<bool>`) and the snackbar (`tr('تم ترحيل القيد.','Entry posted.')` or `accountingErrorText(context, error)`).

- [ ] **Step 4:** Re-run → PASS; analyze clean.

---

### Task 4: Reports domain, repo, shared helpers, DI

**Files:**
- Create: `lib/features/accounting/reports/domain/accounting_reports_models.dart`, `accounting_reports_repo.dart`, `lib/features/accounting/reports/data/accounting_reports_repo_impl.dart`
- Modify: `accounting_ui.dart`, `lib/core/di/app_di.dart`
- Create: `test/accounting_reports_repo_test.dart`

**Interfaces — Produces:**
```dart
class LedgerRow { final String entryId; final DateTime entryDate; final String memo; final num debit, credit, balance; }
class LedgerReport { final String accountId, code, name, type; final num opening, totalDebit, totalCredit, closing; final bool truncated; final List<LedgerRow> rows;
  factory LedgerReport.fromJson(Map<String, dynamic> j); }
class TrialBalanceRow { final String accountId, code, name, type; final num debit, credit;
  factory TrialBalanceRow.fromMap(Map<String, dynamic> m); bool get isZero => debit == 0 && credit == 0; }
class AccountingKpis { final num cashBalance, revenue, expenses, netProfit; final bool hasCashAccounts; final int draftCount, staleDraftCount;
  factory AccountingKpis.fromJson(Map<String, dynamic> j); }

abstract class AccountingReportsRepo {
  Future<LedgerReport> fetchLedger({required String accountId, required DateTime from, required DateTime to});
  Future<List<TrialBalanceRow>> fetchTrialBalance(DateTime asOf);
  Future<AccountingKpis> fetchKpis(DateTime month);
}
// accounting_ui.dart
String accountingBalance(num v);               // 1250 → '1,250.00'; -1250 → '(1,250.00)'
```
- `AppDI.accountingReportsRepo` (`static late final AccountingReportsRepo`, `AccountingReportsRepoImpl(supabase)`).
- Dates sent as `yyyy-MM-dd`. A private `num _num(Object? v)` accepts `int`, `double`, numeric `String`, `null → 0`.

- [ ] **Step 1: Write failing tests** in `accounting_reports_repo_test.dart` (use `server` helper from `employee_attendance_repo_test.dart`):
  - `fetchLedger sends account and date range` → path `/rest/v1/rpc/accounting_ledger`, body `{'p_account_id':'a1','p_from':'2026-10-01','p_to':'2026-10-31'}`; response with `opening: "1000.00"` (string), rows with ints → parsed `opening == 1000`, `rows.first.balance == 600`.
  - `fetchLedger with no rows` → `rows` empty, `closing == opening`.
  - `fetchTrialBalance parses rows` → path `accounting_trial_balance`, body `{'p_as_of':'2026-10-31'}`; empty list response → `[]`.
  - `fetchKpis parses jsonb` → body `{'p_month':'2026-10-01'}`; all-zero payload → zeros and `hasCashAccounts == false`.
  - `accountingBalance` cases: `0 → '0.00'`, `1250 → '1,250.00'`, `-1250.5 → '(1,250.50)'`.

- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Implement models, repo impl (`_client.rpc(...)`; ledger/kpis cast result to `Map<String,dynamic>`, trial balance to `List`), `accountingBalance` (wraps `payrollMoney(v.abs())`), DI registration.
- [ ] **Step 4:** Run → PASS; analyze clean.

---

### Task 5: General Ledger page

**Files:**
- Create: `lib/features/accounting/ledger/view/ledger_cubit.dart`, `lib/features/accounting/ledger/view/ledger_page.dart`
- Modify: `app_router.dart` (import), `app_router_shell_routes_part.dart`, `nav_menu_items_part.dart`, `nav_i18n.dart`
- Create: `test/accounting_ledger_test.dart`

**Interfaces:**
- Consumes: `AccountingReportsRepo.fetchLedger`, `AccountsRepo.fetchAccounts`, `accountingBalance`, `accountingErrorText`.
- Produces: `LedgerPage({AccountingReportsRepo? reportsRepo, AccountsRepo? accountsRepo, String? initialAccountId, DateTime? initialFrom, DateTime? initialTo, DateTime? now})` (defaults from `AppDI`; route reads `?account=`, `?from=`, `?to=` as `yyyy-MM-dd`).
- `LedgerState { List<Account> accounts; String? accountId; DateTime from, to; bool loading; Object? error; LedgerReport? report; }`; `LedgerCubit(reportsRepo, accountsRepo, {required DateTime now})` with `init({String? accountId, DateTime? from, DateTime? to})`, `selectAccount(String id)`, `setRange(DateTime from, DateTime to)`, `refresh()`. Default range: first day of `now`'s month → `now`.

- [ ] **Step 1: Write failing tests** (fakes for both repos):
  - `no account selected shows prompt` → text `Choose an account to view its ledger.`; `fetchLedger` not called.
  - `initialAccountId loads report` → summary cards show `Opening balance 1,000.00`, `Closing balance 600.00`; table shows opening row (`Opening balance`) then one row with memo and `600.00`.
  - `negative balance shows parentheses` → closing `-50` renders `(50.00)`.
  - `truncated banner` → text `Showing the first 2,000 movements. Narrow the date range to see all.`
  - `empty movements` → text `No posted movements in this period.` with opening/closing still shown.
  - `inactive accounts are selectable` → picker lists an inactive account (label suffix ` (Inactive)` / ` (غير نشط)`).
  - `error then retry` → fake throws once → `AppFailureState` retry → loads.
  - Arabic locale smoke: pumps with `Locale('ar')`, no exceptions, heading `دفتر الأستاذ العام`.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3: Implement.** Accounts list: `fetchAccounts(page: 0, pageSize: 1000)` (active and inactive). Picker: `DropdownMenu<String>` with `enableFilter: true`, entries `'${a.code} — ${a.name}'`. Date range: one `OutlinedButton` opening `showDateRangePicker` (guarantees from ≤ to). Heading `accountingHeading(tr('دفتر الأستاذ العام','General Ledger'), tr('حركات الحساب المرحّلة ورصيده الجاري','Posted movements and running balance of one account'))`. Four summary cards: Opening balance / Total debit / Total credit / Closing balance (`الرصيد الافتتاحي / إجمالي المدين / إجمالي الدائن / الرصيد الختامي`). `AccountingTable` headings Date · Memo · Debit · Credit · Balance (`التاريخ · البيان · مدين · دائن · الرصيد`), widths `[16,40,14,14,16]`. Route: `GoRoute(path: AppRoutes.ledger, builder: (c, s) => LedgerPage(initialAccountId: s.uri.queryParameters['account'], initialFrom: DateTime.tryParse(s.uri.queryParameters['from'] ?? ''), initialTo: DateTime.tryParse(s.uri.queryParameters['to'] ?? '')))`. Nav item: label `General Ledger`, icon `Icons.receipt_long_outlined`, roles `['admin','accountant','finance_manager']`, section `_accountingSection`, keywords `['ledger','general ledger','دفتر','أستاذ']`; `nav_i18n` label `دفتر الأستاذ` / `General Ledger` and add the path to the accounting-section condition.
- [ ] **Step 4:** Run → PASS; analyze clean.

---

### Task 6: Trial Balance page

**Files:**
- Create: `lib/features/accounting/trial_balance/view/trial_balance_cubit.dart`, `trial_balance_page.dart`
- Modify: routing + nav files as in Task 5 (constant already added in Task 2)
- Create: `test/accounting_trial_balance_test.dart`

**Interfaces:**
- Consumes: `AccountingReportsRepo.fetchTrialBalance`, `TrialBalanceRow`, `accountingBalance`.
- Produces: `TrialBalancePage({AccountingReportsRepo? repo, DateTime? now, ValueChanged<String>? onOpen})` — `onOpen` receives a full route string; default `context.go`.
- `TrialBalanceCubit(repo, {required DateTime now})`: `load()`, `setAsOf(DateTime)`, `toggleHideZero(bool)`; state `{DateTime asOf; bool hideZero (default true); bool loading; Object? error; List<TrialBalanceRow> rows}`; getters `visibleRows`, `totalDebit`, `totalCredit`, `isBalanced` (`(totalDebit - totalCredit).abs() < 0.005`).

- [ ] **Step 1: Write failing tests:**
  - `groups by type in order Assets, Liabilities, Equity, Income, Expenses` — group header texts appear in that vertical order; rows sorted by code inside group.
  - `totals and Balanced badge` → rows Bank Dr 600, Sales Cr 1000, Salaries Dr 400 → footer `1,000.00` / `1,000.00`, badge `Balanced`.
  - `out of balance badge` → Dr 600 / Cr 500 → `Out of balance by 100.00`.
  - `hide zero balances` → zero row hidden by default; switch off → visible.
  - `tapping a row opens the ledger` → `onOpen` receives `/ledger?account=a1&from=2026-01-01&to=2026-10-31` for asOf 2026-10-31.
  - `empty` → `No posted entries up to this date.`
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3: Implement.** Heading `ميزان المراجعة` / `Trial Balance`, subtitle `أرصدة جميع الحسابات في تاريخ محدد` / `Balance of every account on a date`. Controls: "As of" date button (`showDatePicker`), `Switch` `إخفاء الأرصدة الصفرية` / `Hide zero balances`, Refresh. Group labels: `الأصول / الالتزامات / حقوق الملكية / الإيرادات / المصروفات`. Columns Code · Account · Debit · Credit (`الرمز · الحساب · مدين · دائن`), widths `[14,46,20,20]`. Badges: `متوازن` / `Balanced` (green `0xFF2E7D32`), `غير متوازن بفارق X` / `Out of balance by X` (red `0xFFC62828`). Rows wrapped in `InkWell` with `key: ValueKey('tb-row-<id>')`. Nav item: label `Trial Balance`, icon `Icons.balance_outlined`, keywords `['trial','balance','ميزان','مراجعة']`.
- [ ] **Step 4:** Run → PASS; analyze clean.

---

### Task 7: Accounting KPIs on Finance Home

**Files:**
- Create: `lib/features/finance_home/finance_accounting_kpis.dart`
- Modify: `lib/features/finance_home/finance_home_page.dart` (constructor + mount)
- Create: `test/finance_accounting_kpis_test.dart`; Modify: `test/finance_home_test.dart` (pass a fake reports repo)

**Interfaces:**
- Consumes: `AccountingReportsRepo.fetchKpis`, `AccountingKpis`, `accountingBalance`, `AppRoutes.ledger/trialBalance/journal/accounts`.
- Produces: `FinanceAccountingKpis({required AccountingReportsRepo repo, required DateTime initialMonth, required ValueChanged<String> onOpen})`; `FinanceHomePage` gains `AccountingReportsRepo? reportsRepo` (default `AppDI.accountingReportsRepo`) and mounts the widget as the first child under the gradient header, passing its existing `open`.

- [ ] **Step 1: Write failing tests:**
  - `shows five KPI cards` → texts `Cash balance 600.00`, `Revenue 1,000.00`, `Expenses 400.00`, `Net profit 600.00`, `Drafts to post 1`.
  - `net loss is red and in parentheses` → revenue 100, expenses 400 → `(300.00)` with `TextStyle.color == Color(0xFFC62828)`.
  - `stale drafts alert opens journal` → `staleDraftCount: 2` → text `2 drafts older than 7 days are waiting to be posted`; tap → `onOpen('/journal')`.
  - `no cash accounts hint` → `hasCashAccounts: false` → `No cash accounts marked yet` ; tap → `onOpen('/accounts')`.
  - `month selector reloads` → choose previous month → fake receives `DateTime(2026, 9, 1)`.
  - `KPI error does not break the page` → fake throws → inline text `Accounting figures are unavailable.` + `Retry`; in `finance_home_test.dart` the payroll sections still render.
  - Quick links `General Ledger` → `/ledger`, `Trial Balance` → `/trial-balance`.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3: Implement** a `StatefulWidget` loading on init and on month change; cards in a `Wrap` (min width 180) using `accountingPanel`; Arabic labels `رصيد النقدية / الإيرادات / المصروفات / صافي الربح / مسودات بانتظار الترحيل`; month selector reuses `payrollPeriod(month, ar)` label with prev/next `IconButton`s; alerts as `accountingPanel` rows with `InkWell`. Net profit color green `0xFF2E7D32` when ≥ 0, red `0xFFC62828` when < 0.
- [ ] **Step 4:** Run the two files → PASS; analyze clean.

---

### Task 8: Whole-feature verification

- [ ] **Step 1:** `flutter analyze` (whole project) → no new issues compared with before the work (record the baseline count first).
- [ ] **Step 2:** `flutter test` (whole suite) → all pass.
- [ ] **Step 3:** Hot reload the running app via the Dart MCP tools; `get_runtime_errors` → none.
- [ ] **Step 4:** Give the user a manual checklist (after they ran Task 1 SQL): mark Bank as Cash; create & post 3 entries; open Ledger for Bank and compare running balance by hand; Trial Balance shows Balanced; Finance Home KPIs match; switch to Arabic and repeat a glance check; sign in as `employee` → menu has no accounting items.
- [ ] **Step 5:** Update `docs/accounting_reports_design.md` status to `Implemented` and list the files changed for the user to commit.
