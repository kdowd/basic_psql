# basic_psql — agent context

Handoff notes for this folder. Written to be read cold by a future session.

**This folder is a small PostgreSQL teaching archive: three HTML lessons at three levels,
plus a re-runnable setup script for two of them** (the beginner page has no script on
purpose — it is six commands you type). Every command, result and row count shown on every
page was captured from the live server on this machine. Nothing is mocked up — that is the
whole value of the folder, and the one rule that must not be broken (see §3.1).

---

## 1. Environment facts (hard-won — re-verifying these wastes a lot of time)

* **This is Windows, and it is NOT the machine described in the sibling `AGENTS.md` files.**
  `../supabaseConnect/AGENTS.md` and `../normalsVideo/AGENTS.md` describe Linux boxes
  (`/mnt/...`, `/home/kdowd`, snap, Docker). Ignore their paths and their "no local
  PostgreSQL" claims — they do not apply here.
* Workspace: `E:\dsh_projects\basic_psql`. Shell is **PowerShell (`pwsh`)**, and **every call
  is a fresh process** — no `cwd`, variables or functions carry over. Pass `workdir:` instead
  of using `cd`.
* `psql` is PostgreSQL **18.6**: `C:\Users\OEM\scoop\apps\postgresql\current\bin\psql.exe`.
  Installed via **scoop**.
* **The server is NOT always up — check before assuming.** It is a manually started,
  scoop-installed cluster: **no Windows service** (`Get-Service *postgres*` returns nothing),
  **no scheduled task, no startup entry** — so nothing restarts it automatically and it will
  be **down after a reboot**. It was up early in this session and **verified down at the end
  of it** (`pg_isready` → *no response*, nothing listening on 5432, no `postgres` process);
  nothing in this session ever sent a stop. Start it with (standard for this layout — the
  agent has **not** run this, the user starts it their own way):

  ```powershell
  pg_ctl -D C:\Users\OEM\scoop\persist\postgresql\data -l C:\Users\OEM\scoop\persist\postgresql\data\postgres.log start
  pg_isready -h 127.0.0.1 -p 5432        # expect: accepting connections
  ```

  If a task needs the database, confirm it is up first rather than reporting query failures
  as data problems.
* When it *is* up it listens on **127.0.0.1 and ::1, port 5432 only** — loopback, so it is
  not network-reachable. `psql`, `pg_ctl`, `postgres` and `pg_isready` are on PATH from
  `C:\Users\OEM\scoop\apps\postgresql\current\bin` (no `pg*` shims).
* Data directory: `C:\Users\OEM\scoop\persist\postgresql\data`, with
  `C:\Users\OEM\scoop\apps\postgresql\current\data` as a **junction** pointing at it — either
  path works. `pg_hba.conf` is **`trust` on every local/host line**.
* **There is exactly one login role: `postgres`, a superuser.** Consequence: with trust auth
  on loopback, **any local process can connect as superuser while the server runs**. It is
  the user's server — do not change `pg_hba.conf`, add roles or stop it unasked.
* **There is no role for the Windows user.** Plain `psql` fails with
  `FATAL: role "OEM" does not exist`. Always connect as
  `psql -w -U postgres ...` — the **`-w` matters**, it stops a password prompt from hanging
  the tool call, which is exactly how a 30-second timeout gets burned.
* Databases on the server:

  | Database | Owner | What it is |
  |---|---|---|
  | `basic_psql` | postgres | lesson 1 (`users`, 8 rows) |
  | `gamevault` | postgres | lesson 3 (`games`, 16 rows, kept pristine) |
  | `blahworld` | postgres | **the user's own — do not touch** |
  | `my_special_db` | postgres | **the user's own — do not touch** |

  `toybox` (lesson 2) is **deliberately absent** — see §3.5.
* The **`learning-designer` skill lives in a sibling repo**:
  `E:\dsh_projects\psqlLearn\.dsh\skills\learning-designer\` (`SKILL.md` +
  `lesson-template.md`). It is **not in this workspace's skill catalog**, so the `skill`
  tool cannot load it here (`skill learning-designer` → *unknown or no longer available*).
  Read the two files directly. To make it auto-load, copy the folder to
  `E:\dsh_projects\basic_psql\.dsh\skills\learning-designer\` and restart the session.
* Also in `../psqlLearn/`: `contacts.csv` (100 rows, **no header row**) and the original
  tabbed page (`index.html`, `styles.css`, `rootvars.css`) that this project's look descends
  from. `styles.css` and `rootvars.css` here are **verbatim copies** of those.
* **Do not run `git` inside `../psqlLearn`**: it is owned by `S-1-5-32-544` and git refuses
  with *dubious ownership*. It would need
  `git config --global --add safe.directory E:/dsh_projects/psqlLearn`.
* **No browser or screenshot tool is available in this session.** `read_image` exists, but
  the pages were only ever validated **structurally**, never rendered. Do not claim a page
  "looks right" — say what you checked and let the user be the visual judge (§4).
* `.vscode/` here is the user's editor state. Leave it alone.

---

## 2. What this project is

Three lessons, deliberately written for three different readers. Each is a **single
self-contained HTML file** that opens over `file://`; only `index.html` uses JavaScript.

| File | Reader | Dataset | Shape |
|---|---|---|---|
| `basic_usage.html` | absolute beginner ("databases for a 5-year-old") | `toybox.friends`, 3 rows | one column, 6 steps, no JS |
| `intermediate_usage.html` | intermediate ("for an 18-year-old") | `gamevault.games`, 16 rows | one column, 11 sections, no JS, `<details>` answers |
| `index.html` | reference / practice | `basic_psql.users`, 8 rows | 8-tab shell, tab-switching JS |

The teaching stance: **explain the artefact, not the theory.** Prose is scaffolding around
something the reader runs. Every page states expected row counts so a learner can tell
whether they are right, and `index.html` adds hint ladders (three per exercise, none of
which is a working query).

Companion scripts, both **re-runnable**:

```powershell
psql -w -U postgres -f basic_psql.sql          # resets basic_psql.users to 8 rows
psql -w -U postgres -f intermediate_usage.sql  # resets gamevault.games to 16 rows
```

---

## 3. Hard rules — do not repeat these mistakes

1. **NEVER invent psql output.** Every `output` block on every page must come from a real
   run against the live server, pasted verbatim — including the errors
   (`role "OEM" does not exist`, `invalid input syntax for type integer: "thirty"`,
   `relation "Users" does not exist`). If you catch yourself typing plausible-looking
   output, stop and go run the query. This folder's credibility is its only asset.
2. **Capture with `psql -w -U postgres -X -a -f script.sql`.** `-a` (echo-all) prints each
   command followed by its output, which is exactly the transcript shape the pages use.
   `-X` skips any `psqlrc` startup file the user may add later (on Windows that is
   `%APPDATA%\postgresql\psqlrc.conf`), keeping captures reproducible.
3. **stderr is not interleaved with stdout the way you expect.** Verified: with `-a` and
   `2>&1` and **no downstream pipeline**, the `ERROR:` lines are printed **after all
   stdout**, out of execution order — the transcript lies about where the failure happened.
   Piping through a filter (`| Select-String ...`) preserves the order. So: if the
   *position* of an error matters in a transcript, run that statement on its own.
4. **Capture reads before writes, in the page's narrative order, from a freshly reset DB.**
   A learner reads top to bottom. If a mutating section (the `UPDATE`/`DELETE` in
   `intermediate_usage.html` §9–10) runs before you capture the earlier queries, the numbers
   on the page will not match what the reader sees.
5. **Decide the capture database's fate deliberately, and write it down.** Two different
   choices were made here, both defensible:
   * `basic_usage.html` — `toybox` was created to capture real output, then **dropped**, so
     step 2 works the first time for the most fragile reader.
   * `intermediate_usage.html` — `gamevault` was **left in place, pristine**, so the user
     can jump to any section and see matching output; the page therefore documents the
     `database "gamevault" already exists` message instead of hiding it.
   What must never happen: a beginner hits an unexplained error at step 2.
6. **A companion script must survive being run twice.** `DROP TABLE IF EXISTS` before
   `CREATE TABLE`; `CREATE DATABASE` reporting *already exists* is expected and harmless
   because `ON_ERROR_STOP` is not set. This was a real bug: `basic_psql.sql` originally
   re-ran its `INSERT` and silently produced **16 rows**, breaking every expected count in
   the lesson. It was fixed and the fix was announced (§3.10).
7. **Verify every number you assert — then verify again from a fresh reset.** Several
   first-guess numbers here were wrong: `count(rating)` is **13**, not 14 (three rows are
   unrated, not two), and two filters return one row fewer than guessed. Reason about the
   query, then **run it** and copy what comes back. See §5 for the oracles.
8. **HTML escaping, or the SQL silently disappears.** Inside `<pre>`/`<code>`: `<` → `&lt;`,
   `>` → `&gt;`, `&` → `&amp;` (`'Salt & Cinder'` must be `'Salt &amp; Cinder'` in the file
   text; the browser renders it back to `&`, so copy-paste stays correct). Inside
   `<script>`, `&&` stays **raw** — script content is not entity-decoded.
9. **Never touch the user's own databases** (`blahworld`, `my_special_db`) and never edit
   `../psqlLearn`. Reset only `basic_psql` / `gamevault` / your own capture databases.
10. **If you revise a file the user may already have run or read, say so loudly.** (Borrowed
    from `../supabaseConnect/AGENTS.md` §3.7.) One file here was already in the user's hands
    when it changed — `basic_psql.sql`, the re-runnability fix in §3.6. Announcing it cost
    one line; not announcing it would have cost a debugging round trip.

---

## 4. Verification discipline

**Static structure** — run this after every edit to a page. It catches unbalanced tags, a
tab pointing at a section that does not exist, and unescaped brackets:

```powershell
$txt = Get-Content E:\dsh_projects\basic_psql\index.html -Raw
foreach ($t in @('div','section','pre','details','table','p','ul','li')) {
  $o = ([regex]::Matches($txt, "<$t[ >]")).Count
  $c = ([regex]::Matches($txt, "</$t>")).Count
  if ($o -ne $c) { "MISMATCH {0}: {1} / {2}" -f $t, $o, $c }
}
"bare '<' : " + ([regex]::Matches($txt, '<(?![a-zA-Z/!])')).Count   # expect 1: the JS `i < tabs.length`
"bad '&'  : " + ([regex]::Matches($txt, '&(?!(amp|lt|gt|quot|#\d+);)')).Count
$controls = [regex]::Matches($txt, 'aria-controls="([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
$ids      = [regex]::Matches($txt, 'section id="([^"]+)"')   | ForEach-Object { $_.Groups[1].Value }
"wiring ok: " + (($controls -join ',') -eq ($ids -join ','))
```

(The raw-`&` count is legitimately non-zero for `index.html`: `&&` inside its `<script>`.)

**Numbers** — every asserted figure has a query. Re-run them against a freshly reset
database and compare against §5 before claiming a page is correct.

**Honest limit:** there is no way in this session to render a page. Structural validation is
not visual validation. Say so explicitly rather than implying the layout was seen.

---

## 5. Test oracles (real values, verified — use these instead of re-deriving)

`basic_psql.users` — 8 rows, 4 columns, **no primary key** (that is the point: `\di` reports
*Did not find any indexes*).

| Fact | Value |
|---|---|
| Rows inserted | 8 |
| `count(age)` | 7 (Priya has no age) |
| `count(email)` | 7 (Tomas has no email) |
| `avg(age)` | 36.0 |
| Age ≥ 18, oldest first | 6 rows (Sofia is 17; Priya drops out as NULL) |
| Duplicate person | Mary Johnson ×2, one email capitalised `Mary.Johnson@Example.Com` |
| `lower(email) = 'mary.johnson@example.com'` | 2 rows (the exact-match version returns 1) |

`gamevault.games` — 16 rows pristine, 8 columns, identity primary key.

| Fact | Value |
|---|---|
| Rows | 16 |
| `count(rating)` | **13** (Static Bloom, Glasshouse, Marrow are NULL) |
| `count(DISTINCT genre)` | 6 |
| `avg(rating)` / `sum(price)` | 4.11 / 458.86 |
| Not finished | 8 |
| `price >= 50` | 2 rows |
| `released >= '2023-01-01'` | 6 rows |
| Never played (`hours_played = 0`) | 1 row, 27.50 |
| Duplicate group | `Paper Skies` ×2 (ids 3 and 12) |
| Missing-WHERE demo | `UPDATE 16`, then `ROLLBACK` returns `price > 60` to 1 |
| After §9–10 of the lesson | 15 rows (id 12 deleted, Redline Zero finished) |

### Quoted identifiers vs string literals (the user asked — answered with real output)

`SELECT * FROM games WHERE title = "Neon Drift";` **raises an error, it does not return zero
rows**:

```
ERROR:  column "Neon Drift" does not exist
LINE 1: SELECT * FROM games WHERE title = "Neon Drift";
                                          ^
```

Double quotes are **identifiers** in PostgreSQL (as the SQL standard requires); single quotes
are string literals. The near-miss that *does* return nothing, silently, is the
correct-quotes / wrong-case version — verified on `gamevault`:

| Query | Result |
|---|---|
| `title = 'Neon Drift'` | 1 row |
| `title = 'neon drift'` | `(0 rows)`, no error |
| `title ILIKE 'neon drift'` | 1 row |
| `"title" = 'Neon Drift'` | 1 row (quoting a real identifier is legal) |
| `SELECT "Title" FROM games` | `ERROR: column "Title" does not exist` + a *Perhaps you meant* hint |

Read the response shape to tell the two failure modes apart: **`(0 rows)`** means the query
ran and the filter matched nothing (a data problem); **`ERROR: column … does not exist`**
means the query never ran (a name problem, and the caret points at the culprit). MySQL in
default mode and SQLite both treat `"…"` as a string, so this pattern works elsewhere and
fails here — a likely source of future confusion.

This is the same rule as the `"Users"` trap on `index.html` (identifier case-folding), seen
from the other direction.

---

## 6. File inventory

| File | Purpose |
|---|---|
| `AGENTS.md` | this file |
| `basic_usage.html` | beginner lesson; `toybox` / `friends`; 6 steps; inline CSS + `rootvars.css`; no JS |
| `intermediate_usage.html` | intermediate lesson; `gamevault` / `games`; 11 sections; `<details>` answers; no JS |
| `index.html` | reference lesson; `basic_psql` / `users`; 8 tabs (Objectives, Setup, Build it, Practice, Solutions, Traps, Transfer, Cheatsheet) |
| `basic_psql.sql` | lesson 1 script; re-runnable; resets `users` to 8 rows |
| `intermediate_usage.sql` | lesson 3 script; re-runnable; resets `games` to 16 rows |
| `rootvars.css`, `styles.css` | verbatim copies of the `../psqlLearn` shell styles — used by `index.html` only |
| `lesson.css` | lesson-specific styles for the tabbed page (code/output blocks, hint ladders, cards) |
| `.vscode/` | the user's own editor state — leave alone |

The two single-column pages deliberately **do not** link `styles.css`/`lesson.css`: they are
self-contained apart from `rootvars.css`, which supplies the light/dark palette.

---

## 7. Current state / open threads

* **All three pages are built, verified, and reviewed by the user** — their verdict on the
  finished set was "great work", with **no defects reported** and no page yet confirmed
  rendered in a browser. This session ended here.
* `gamevault` is **pristine at 16 rows** on purpose; `basic_psql` holds 8 users rows;
  `toybox` is intentionally **not** on the server.
* **But the server was stopped at session end** (§1), so those row counts are from the last
  check *while it was up* and could not be re-confirmed afterwards. The data is intact on
  disk — `base/` under the data directory holds **7** database directories, matching the 7
  databases listed in §1. Start the server (command in §1) before verifying anything.
* **Offered, not built:** automatic answer checking. `intermediate_usage.html`'s exercises
  give answers in `<details>` with expected row counts, but the learner compares manually.
  The cheap fix is a check query under each exercise, as `index.html` does.
* **Offered, not done:** copying the `learning-designer` skill into
  `E:\dsh_projects\basic_psql\.dsh\skills\` so it auto-loads here (§1).
* **Declined by the user — do not re-offer unasked:** adding the string-vs-identifier quoting
  trap (§5) as a fourth card on `index.html`'s Traps tab. Answer: "no its fine". The finding
  is recorded in §5 so it is not lost; if the Traps tab is ever revised for another reason,
  it is a two-line addition that fits beside the existing `"Users"` card.
* **Unverified visually:** `index.html`'s tab rail carries **8** tabs (the original
  `../psqlLearn` shell had 5). It may look crowded on a narrow window. Nobody has rendered it.
* Page order across the folder is a deliberate progression — `basic_usage.html` →
  `intermediate_usage.html` → `index.html` — and the pages cross-link in that order.
* If the user asks for the next lesson, the rung after intermediate is a **second table and a
  `JOIN`** (genres moved to their own table with a foreign key). That is already trailed at
  the end of `intermediate_usage.html`.
* This `AGENTS.md` is loaded by DSH as workspace instructions (it took effect mid-session on
  creation). Keep it accurate — a wrong "fact" here is worse than no file, because a future
  session will trust it instead of re-checking.
