# basic_psql — agent context

Handoff notes for this folder. Written to be read cold by a future session.

**This folder is a small PostgreSQL teaching archive: four HTML lessons at four levels,
plus a re-runnable setup script for three of them** (the beginner page has no script on
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
* **The site has a shared chrome file: `menu.css`.** Every page links `./rootvars.css` **and**
  `./menu.css`, and carries the same header markup — a `<p>Built using …</p>` followed by a
  `<div class="hero-menu">` of links (Home / Basic Usage / Intermediate Usage). `menu.css` owns
  `body` and `.site-header`, which were **moved out of `styles.css`** (it shrank from 5569 to
  5038 bytes); `index.html` additionally links `styles.css` + `lesson.css` for the tab shell.
  The user writes HTML with **2-space indent and self-closing `<meta />` / `<link />`** — match
  that formatting when editing their pages.
* `psql` is PostgreSQL **18.6**: `C:\Users\OEM\scoop\apps\postgresql\current\bin\psql.exe`.
  Installed via **scoop**.
* **Image tooling on this box** (probed, not assumed — it backs the `images/` assets):
  * **PowerShell + `System.Drawing`** works (`Add-Type -AssemblyName System.Drawing`) — best for
    hand-laid-out diagrams and cards.
  * **ffmpeg 9.0.2** (`C:\ProgramData\chocolatey\bin\ffmpeg.exe`, gyan.dev *essentials* build)
    still ships `drawtext` (libfreetype), `gradients`, `mandelbrot`, `life`, `cellauto` and the
    PNG encoder after the v6 → v9 upgrade. Its `drawtext` needs the font-path colon escaped:
    `fontfile='C\:/Windows/Fonts/segoeuib.ttf'`.
  * **Python 3.15.0b3** with **Pillow 12.3.0** and **numpy 2.5.3**, both user-installed. The
    Pillow wheel is `cp315-win_amd64`, so it installs with no compiler — check a wheel exists
    **before** suggesting an install, since 3.15 is a beta.
  * **Node 24 + `sharp`** (ships with DSH at `profiles/node_modules/sharp`) — SVG → PNG.
  * **No ImageMagick** — `magick` is not installed, so do not reach for it.
  * `read_image` **works for this model**: any generated image can and should be *looked at*
    before it is handed over. Never trust an exit code or "no overflow warnings" alone.
* **The server is NOT always up — check before assuming.** It is a manually started,
  scoop-installed cluster: **no Windows service** (`Get-Service *postgres*` returns nothing),
  **no scheduled task, no startup entry** — so nothing restarts it automatically and it will
  be **down after a reboot**. Observed both ways: **down at the end of one session**
  (`pg_isready` → *no response*, nothing listening on 5432, no `postgres` process; nothing in
  that session ever sent a stop) and **up again at the start of the next** — the user starts
  it themselves. **How to start it — the obvious way is a trap; this way is verified.** Running
  `pg_ctl ... start` directly inside a tool call means that when the call hits its timeout, the
  postmaster dies with the process tree, **mid-startup**, leaving an unclean shutdown — the next
  start then does crash recovery (`database system was not properly shut down; automatic
  recovery in progress` in the log) and the call is wasted. Start it **detached**:

  ```powershell
  $exe = "C:\Users\OEM\scoop\apps\postgresql\current\bin\pg_ctl.exe"
  Start-Process -FilePath $exe -WindowStyle Hidden -ArgumentList @(
    '-D','C:\Users\OEM\scoop\persist\postgresql\data',
    '-l','C:\Users\OEM\scoop\persist\postgresql\data\postgres.log','start')
  pg_isready -h 127.0.0.1 -p 5432     # may report "rejecting connections" for a few seconds
  ```

  Expect **7 `postgres` processes** once it is up. Two harmless log lines to expect: a *sharing
  violation* on `./postgres.log` during recovery (the `-l` handle collides; it retries), and
  crash-recovery messages if the previous shutdown was unclean.

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
  | `jobsdb` | postgres | lesson 4 (`people_flat` 8, `people` 8, `jobs` 6; kept pristine) |
  | `tasks_db` | postgres | **the user's own — their import target.** Holds `people_flat` at **16** rows: their 8-row file imported twice |
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
  from. `rootvars.css` here is a **verbatim copy** of that one; `styles.css` has since been
  **modified by the user** — `body` / `.site-header` moved out into `menu.css` (see §6).
* **Do not run `git` inside `../psqlLearn`**: it is owned by `S-1-5-32-544` and git refuses
  with *dubious ownership*. It would need
  `git config --global --add safe.directory E:/dsh_projects/psqlLearn`.
* **No browser or screenshot tool is available in this session.** `read_image` exists, but
  the pages were only ever validated **structurally**, never rendered. Do not claim a page
  "looks right" — say what you checked and let the user be the visual judge (§4).
* `.vscode/` here is the user's editor state. Leave it alone.

---

## 2. What this project is

Four lessons, deliberately written for four different readers. Each is a **single
self-contained HTML file** that opens over `file://`; only `index.html` uses JavaScript.

| File | Reader | Dataset | Shape |
|---|---|---|---|
| `basic_usage.html` | absolute beginner ("databases for a 5-year-old") | `toybox.friends`, 3 rows | one column, 6 steps, no JS |
| `intermediate_usage.html` | intermediate ("for an 18-year-old") | `gamevault.games`, 16 rows | one column, 11 sections, no JS, `<details>` answers |
| `second_normal.html` | normalisation / why tables get split | `jobsdb`: `people_flat` (8) vs `people` + `jobs` | one column, 7 sections, no JS, `<details>` answers |
| `index.html` | reference / practice | `basic_psql.users`, 8 rows | 8-tab shell, tab-switching JS |

The teaching stance: **explain the artefact, not the theory.** Prose is scaffolding around
something the reader runs. Every page states expected row counts so a learner can tell
whether they are right, and `index.html` adds hint ladders (three per exercise, none of
which is a working query).

Companion scripts, all three **re-runnable**:

```powershell
psql -w -U postgres -f basic_psql.sql          # resets basic_psql.users to 8 rows
psql -w -U postgres -f intermediate_usage.sql  # resets gamevault.games to 16 rows
psql -w -U postgres -f second_normal.sql       # resets jobsdb to 8 / 8 / 6
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
   **The flip side, learned from the user's own import:** "psql carries on after an error" is
   harmless for `CREATE DATABASE` but **dangerous for a data file**. Their `people_flat.sql`
   (8 rows) was imported twice into `tasks_db`; the second run failed only on
   `relation "people_flat" already exists`, then the `INSERT` ran anyway and left **16 rows**
   (verified: Electrician 6 instead of 3, every other job 2, only 8 distinct rows). So any
   file that both creates and fills a table needs a guarded `DROP TABLE IF EXISTS` or a loud
   warning — the damage is invisible in the row counts.
7. **Verify every number you assert — then verify again from a fresh reset.** Several
   first-guess numbers here were wrong: `count(rating)` is **13**, not 14 (three rows are
   unrated, not two), and two filters return one row fewer than guessed. Reason about the
   query, then **run it** and copy what comes back. See §5 for the oracles. A third instance:
   a cross-join row count was written as **48** (8 × 6) and *measured* **56** — right only in
   the pristine state, wrong after an earlier exercise had added a 7th job. State the row
   count **and** the state it holds in.
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
11. **Non-ASCII characters on the PowerShell command line break queries.** Passing an accented
    literal through `psql -c "... 'José' ..."` sends `é` as the single byte `0xE9`
    (Windows-1252) and the server rejects it:
    `ERROR: invalid byte sequence for encoding "UTF8": 0xe9 0x27 0x2c`. That is a **shell
    encoding** fault, not a data fault — the identical literal inside a UTF-8 `.sql` file run
    with `-f` / `\i` imports perfectly. To query accented data without trusting the command
    line, use `U&'Jos\00E9'` escapes, or locate the rows with
    `octet_length(x) <> length(x)`.

---

## 4. Verification discipline

**Static structure** — run this after every edit to a page. It catches unbalanced tags, a
tab pointing at a section that does not exist, and unescaped brackets:

```powershell
$txt = Get-Content E:\dsh_projects\basic_psql\index.html -Raw
foreach ($t in @('div','section','pre','details','table','p','ul','li')) {
  $o = ([regex]::Matches($txt, "<$t[ >]")).Count
  $c = ([regex]::Matches($txt, "</$t")).Count   # plain prefix, NOT "</$t>" — see the note below
  if ($o -ne $c) { "MISMATCH {0}: {1} / {2}" -f $t, $o, $c }
}
"bare '<' : " + ([regex]::Matches($txt, '<(?![a-zA-Z/!])')).Count   # expect 1: the JS `i < tabs.length`
"bad '&'  : " + ([regex]::Matches($txt, '&(?!(amp|lt|gt|quot|#\d+);)')).Count
$controls = [regex]::Matches($txt, 'aria-controls="([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
$ids      = [regex]::Matches($txt, 'section id="([^"]+)"')   | ForEach-Object { $_.Groups[1].Value }
"wiring ok: " + (($controls -join ',') -eq ($ids -join ','))
```

(The raw-`&` count is legitimately non-zero for `index.html`: `&&` inside its `<script>`.)

**The false alarm this snippet already caused — read before reporting broken HTML.** The
user's reformatted pages wrap some end tags as `</pre` + newline + indentation + `>`. That is
**valid HTML** and renders identically, but a strict `</pre>` regex misses it and reports a
bogus imbalance (**34** occurrences in `index.html`, 1 in `basic_usage.html`; the plain
`<pre` / `</pre` counts are exactly balanced). Diagnosed by dumping the characters after each
match: `>\n  ` ×23 and `\n   ` ×34. Hence the plain-prefix end-tag count above. Do not
"tidy" the user's wrapping unasked, and do not report their pages as broken on this basis.

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

`jobsdb` (lesson 4) — one flat table against the split pair, kept pristine at 8 / 8 / 6.

| Fact | Value |
|---|---|
| `people_flat` rows | 8 (Dave Smith … Ayub Bachchu) |
| `jobs` rows | **6** — `Electrician` stored once, not three times |
| `people` rows | 8, with `job_id` 1,2,1,3,4,1,5,6 |
| Repetition | `Electrician` ×3; every other title ×1 |
| Update anomaly (flat) | `UPDATE 3` for one logical rename; the same change on `jobs` is `UPDATE 1` |
| Delete anomaly (flat) | deleting Bachchu drops `count(DISTINCT job_title)` **6 → 5** |
| Insert anomaly (flat) | `(NULL, NULL, 'Blacksmith')` → `violates not-null constraint` |
| Loss check | `EXCEPT` both directions between flat and joined = **0** and **0** |
| Cross join | `FROM people, jobs` = **48** (8 × 6) *in the pristine state*; 56 once exercise 3 adds a 7th job |
| Constraint errors | FK rejects `job_id = 99`; FK blocks deleting `jobs.id = 1`; `UNIQUE` rejects a second `'Plumber'` |
| Typo ceiling | `'Electrican'` inserts cleanly — `UNIQUE` cannot catch a misspelling, so the split makes typos *visible*, not impossible |

**Content decision recorded: the page is deliberately honest about the normal form.** The
user's original three-column idea (`firstname, lastname, job_title`) is **already in 2NF and
3NF** — there is no composite key, so no partial dependency can exist. The page states that
in §7, frames the split as *extracting a lookup table*, and then sketches the genuinely-2NF
case (composite key plus a job-owned `rate`, whose fix needs **three** tables). The user chose
this framing. **Do not "correct" the page into claiming the two-table split is a 2NF
violation** — that is the common textbook error this page exists to avoid.

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
| `second_normal.html` | normalisation lesson; `jobsdb`: flat table vs two split tables; 7 sections; `<details>` answers; no JS |
| `index.html` | reference lesson; `basic_psql` / `users`; 8 tabs (Objectives, Setup, Build it, Practice, Solutions, Traps, Transfer, Cheatsheet) |
| `basic_psql.sql` | lesson 1 script; re-runnable; resets `users` to 8 rows |
| `intermediate_usage.sql` | lesson 3 script; re-runnable; resets `games` to 16 rows |
| `second_normal.sql` | lesson 4 script; re-runnable; resets `jobsdb` to 8 / 8 / 6 |
| `people_flat.sql` | **the user's own file** — their `CREATE TABLE` + the original 8 rows. Do not edit unless asked |
| `people_flat_100.sql` | 100-row import file: the same `CREATE TABLE` + 100 rows, 13 job titles. Built for `\i` into an empty database; verified by importing into a scratch DB |
| `menu.css` | **the user's own shared chrome** — `body` + `.site-header` + `.hero-menu`; linked by every page |
| `rootvars.css` | verbatim copy of the `../psqlLearn` palette (light/dark) |
| `styles.css` | **user-modified** since the copy: `body`/`.site-header` moved out to `menu.css`. Tab shell + panel styles for `index.html` only |
| `lesson.css` | lesson-specific styles for the tabbed page (code/output blocks, hint ladders, cards) |
| `images/postgres-on-windows.png` | **the teaching diagram**: Windows *service/daemon* (background) vs *psql client* (foreground). Drawn by the script beside it |
| `images/make_service_diagram.py` | Pillow script that renders that diagram; it self-reports any text that overflows its box, so re-runs are safe |
| `images/jobs-chart.png` | bar chart of the 100-row catalogue (Pillow + numpy; data parsed from `people_flat_100.sql`) |
| `images/gdi-proof.png`, `images/ffmpeg-proof.png` | capability proofs for the GDI+ and ffmpeg PNG routes |
| `.vscode/` | the user's own editor state — leave alone |

The three single-column pages (`basic_usage.html`, `intermediate_usage.html`,
`second_normal.html`) deliberately **do not** link `styles.css` / `lesson.css`: each carries
its own inline `<style>` and is self-contained apart from `rootvars.css` + `menu.css`.

---

## 7. Current state / open threads

* **Four pages are built and verified.** The first three were reviewed by the user with no
  defects reported ("great work"); `second_normal.html` was added in a later session and has
  not been reviewed yet. **No page has ever been confirmed rendered in a browser.**
* `second_normal.html` + `second_normal.sql` are new, and `jobsdb` is **left in place,
  pristine at 8 / 8 / 6** so the user can jump to any section and see matching output — the
  page therefore documents the `database "jobsdb" already exists` message, same choice as
  `gamevault` (§3.5).
* **The new page was deliberately NOT added to the site menu.** The user chose "build the new
  page only" and will wire the `hero-menu` link themselves. The page carries the same
  three-link menu as the others, so the menus stay identical until they edit them. **Do not
  add a fourth link to the other pages unasked.**
* `gamevault` is **pristine at 16 rows**; `basic_psql` holds 8 users rows; `toybox` is
  intentionally **not** on the server. The server was **up** at the start of the latest
  session, so every oracle in §5 has been verified against a live server at least once.
* **Server state right now: UP.** The agent started it this session using the detached
  `Start-Process` recipe in §1 (after a first attempt that the tool timeout killed). It has
  **not** been stopped — stopping was never requested. Finding it down next time is normal.
* **`images/` was added at the user's request** — a service-vs-client teaching diagram, a bar
  chart of the 100-row catalogue, two capability proofs, and the script that draws the
  diagram. Every image was **looked at with `read_image`** before being handed over, and the
  diagram was re-rendered once after the first version left dead space in the terminal mock.
  **Nothing in `images/` is referenced by any lesson page yet** — that has not been asked for.
  The Windows service name, path and startup type in the diagram are **installer defaults**,
  not facts about this box (this box has *no* service) — the footnote in the image says so.
* **`people_flat_100.sql` was requested and delivered** — the user's `CREATE TABLE` verbatim
  plus 100 rows across 13 job titles, for `\i` into an empty database. Verified by importing
  into a scratch database with `\i` (got `CREATE TABLE` + `INSERT 0 100`) and then dropping it.
  The user's own `people_flat.sql` (8 rows) was left untouched.
* **`tasks_db.people_flat` currently holds 16 rows**, doubled by two imports of their 8-row
  file (§3.6). This was reported to them along with the three ways out (empty database, a
  manual `DROP TABLE`, or uncommenting the guarded `DROP` in the new file). Do not "fix" it
  unasked — it is their database and their decision.
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
  `intermediate_usage.html` → `second_normal.html` → `index.html`. Note the pages do **not**
  yet all cross-link in that order: `basic_usage.html`, `intermediate_usage.html` and
  `second_normal.html` each link to `index.html`, but nothing yet links *to*
  `second_normal.html` (see the menu bullet above).
* If the user asks for the next lesson, the natural rung after `second_normal.html` is the
  **three-table version**: a person with more than one job, which moves `job_id` out of
  `people` into a link table — the `work(person_id, job_id)` shape sketched at the end of that
  page. Aggregates/`JOIN` depth already lives in `intermediate_usage.html`.
* This `AGENTS.md` is loaded by DSH as workspace instructions (it took effect mid-session on
  creation). Keep it accurate — a wrong "fact" here is worse than no file, because a future
  session will trust it instead of re-checking.
