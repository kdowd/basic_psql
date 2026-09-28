"""make_service_diagram.py - draw the "PostgreSQL on Windows 11" teaching diagram.

One PNG showing the two halves students must not confuse:
  * the server: a background Windows service (a daemon) that owns the data
  * psql: a foreground client that only sends SQL and prints what comes back

All psql output shown in the terminal mock was captured verbatim from this machine.

Usage:  python make_service_diagram.py [output.png]
"""

import sys
from PIL import Image, ImageDraw, ImageFont

OUT = sys.argv[1] if len(sys.argv) > 1 else "postgres-on-windows.png"

W, H = 1600, 1196

BG = (20, 23, 28)
PANEL = (27, 31, 38)
PANEL2 = (32, 37, 45)
TERM = (16, 18, 22)
BORDER = (46, 53, 64)
INK = (232, 235, 239)
MUTED = (154, 164, 178)
FAINT = (122, 132, 148)
ACCENT = (37, 99, 235)
ACCENT_HI = (107, 155, 255)
GREEN = (52, 199, 89)

F = "C:/Windows/Fonts/"
f_title = ImageFont.truetype(F + "segoeuib.ttf", 43)
f_sub = ImageFont.truetype(F + "segoeui.ttf", 21)
f_zone = ImageFont.truetype(F + "segoeuib.ttf", 17)
f_zsub = ImageFont.truetype(F + "segoeui.ttf", 16)
f_h = ImageFont.truetype(F + "segoeuib.ttf", 24)
f_body = ImageFont.truetype(F + "segoeui.ttf", 18)
f_small = ImageFont.truetype(F + "segoeui.ttf", 16)
f_chip = ImageFont.truetype(F + "segoeuib.ttf", 16)
f_code = ImageFont.truetype(F + "consola.ttf", 15)
f_codeb = ImageFont.truetype(F + "consolab.ttf", 17)
f_term = ImageFont.truetype(F + "consola.ttf", 16)
f_termb = ImageFont.truetype(F + "consolab.ttf", 16)
f_take_h = ImageFont.truetype(F + "segoeuib.ttf", 18)
f_take_b = ImageFont.truetype(F + "segoeui.ttf", 16)
f_foot = ImageFont.truetype(F + "segoeui.ttf", 15)

img = Image.new("RGB", (W, H), BG)
d = ImageDraw.Draw(img)

problems = []


def fit(s, font, maxw, tag=""):
    """Truncate with an ellipsis if the string is wider than maxw, and complain."""
    if d.textlength(s, font=font) <= maxw:
        return s
    problems.append(f"{tag or s[:28]!r} overflows {maxw:.0f}px")
    while s and d.textlength(s + "\u2026", font=font) > maxw:
        s = s[:-1]
    return s + "\u2026"


def panel(box, fill=PANEL, outline=BORDER, r=18, width=1):
    d.rounded_rectangle(box, radius=r, fill=fill, outline=outline, width=width)


def down_arrow(x, y0, y1, color=ACCENT_HI, w=4):
    d.line([(x, y0), (x, y1 - 12)], fill=color, width=w)
    d.polygon([(x - 9, y1 - 13), (x + 9, y1 - 13), (x, y1)], fill=color)


def both_arrow(x, y0, y1, color=ACCENT_HI, w=4):
    d.line([(x, y0 + 11), (x, y1 - 11)], fill=color, width=w)
    d.polygon([(x - 8, y0 + 12), (x + 8, y0 + 12), (x, y0)], fill=color)
    d.polygon([(x - 8, y1 - 12), (x + 8, y1 - 12), (x, y1)], fill=color)


# ---------------------------------------------------------------- header
d.text((70, 50), "What is actually happening on your PC", font=f_title, fill=INK)
d.text((72, 112),
       "PostgreSQL on Windows 11: a background service does the work \u2014 psql is the client you talk to it with",
       font=f_sub, fill=MUTED)

# ------------------------------------------------- zone 1: the server
panel((60, 168, 1540, 600))
d.text((92, 188), "WINDOWS 11   \u00b7   BACKGROUND", font=f_zone, fill=ACCENT_HI)
d.text((92, 212), "started at boot, runs whether or not you are logged in", font=f_zsub, fill=FAINT)

# services row
panel((100, 246, 1500, 322), fill=PANEL2, r=12)
d.text((128, 274), "Services  (services.msc)", font=f_body, fill=INK)
panel((960, 262, 1472, 306), fill=PANEL, r=9)
d.ellipse((984, 279, 996, 291), fill=GREEN)
d.text((1008, 273), fit("postgresql-x64-18", f_codeb, 250, "service name"), font=f_codeb, fill=INK)
d.text((1180, 273), "Running", font=f_codeb, fill=GREEN)
d.text((1330, 274), "Startup: Automatic", font=f_small, fill=MUTED)

down_arrow(150, 322, 372)
d.text((182, 334), "Windows starts it for you \u2014 there is no window and nothing to click", font=f_small, fill=MUTED)

# the daemon
panel((100, 372, 1500, 576), fill=PANEL2, r=12)
d.rounded_rectangle((100, 372, 110, 576), radius=12, fill=ACCENT)
d.text((142, 396), "postgres.exe", font=f_h, fill=INK)
d.text((300, 400), "the database server \u2014 a daemon", font=f_body, fill=MUTED)

bullets = [
    "one long-running process: no window, no menus, no user interface",
    "listens on 127.0.0.1:5432 \u2014 this machine only, unreachable from the network",
    "opens one backend process per connection, and owns every byte of your data",
]
y = 448
for b in bullets:
    d.text((142, y), "\u2022", font=f_body, fill=ACCENT_HI)
    d.text((162, y), fit(b, f_body, 800, "daemon bullet"), font=f_body, fill=MUTED)
    y += 32

panel((1000, 388, 1476, 560), fill=PANEL, r=12)
d.text((1024, 406), "Data directory", font=f_zone, fill=ACCENT_HI)
d.text((1024, 434), fit(r"C:\Program Files\PostgreSQL\18\data", f_code, 440, "data path"), font=f_code, fill=INK)
for i, line in enumerate([
    "your tables, indexes and write-ahead log",
    "are FILES in here.",
    "Nothing lives inside psql.",
]):
    d.text((1024, 468 + i * 26), line, font=f_small, fill=MUTED)

# --------------------------------------------- the connection
both_arrow(150, 604, 724)
d.text((186, 616), fit("TCP 127.0.0.1:5432", f_codeb, 400, "socket label"), font=f_codeb, fill=ACCENT_HI)
d.text((186, 646), "your SQL goes down   \u2193", font=f_body, fill=MUTED)
d.text((186, 674), "rows come back up   \u2191", font=f_body, fill=MUTED)

d.text((620, 640), "The same socket serves every client \u2014", font=f_body, fill=MUTED)
chip_x = 620
for name in ["psql", "pgAdmin", "a Python script", "your app"]:
    tw = d.textlength(name, font=f_chip)
    panel((chip_x, 672, chip_x + tw + 34, 706), fill=PANEL2, r=9, outline=BORDER)
    d.text((chip_x + 17, 680), name, font=f_chip, fill=INK)
    chip_x += tw + 50

# ------------------------------------------- zone 2: your session
panel((60, 728, 1540, 1030))
d.text((92, 748), "YOUR SESSION   \u00b7   FOREGROUND", font=f_zone, fill=ACCENT_HI)
d.text((92, 772), "alive only while you are using it", font=f_zsub, fill=FAINT)

# terminal
panel((100, 806, 980, 1000), fill=TERM, r=12)
panel((100, 806, 980, 838), fill=PANEL2, r=12)
d.rectangle((100, 830, 980, 838), fill=PANEL2)
d.text((124, 812), "Windows Terminal  \u2014  psql", font=f_small, fill=MUTED)
for cx, col in ((930, (255, 95, 86)), (954, (255, 189, 46)), (978, (39, 201, 63))):
    d.ellipse((cx - 6, 817, cx + 6, 829), fill=col)

term_lines = [
    (r"C:\> psql -U postgres -d jobsdb", INK),
    ("jobsdb=# SELECT count(*) AS rows_in_table FROM people_flat;", INK),
    (" rows_in_table", MUTED),
    ("---------------", MUTED),
    ("              8", INK),
    ("(1 row)", MUTED),
    ("", MUTED),
    (r"jobsdb=# \q", INK),
]
ty = 848
for line, col in term_lines:
    d.text((124, ty), fit(line, f_term, 560, "terminal line"), font=f_term, fill=col)
    ty += 19

# what each part of that transcript actually did
d.text((722, 866), "\u2191  sent to the server", font=f_chip, fill=ACCENT_HI)
d.text((722, 923), "\u2193  the server's answer", font=f_chip, fill=ACCENT_HI)
d.text((722, 980), "closes the client only", font=f_chip, fill=FAINT)

# right-hand explanation
d.text((1024, 806), "psql is only a window into the server.", font=f_h, fill=INK)
notes = [
    "It stores nothing. It has no data of its own. It opens a",
    "connection, sends your SQL, and prints what comes back.",
    "",
    "Typing \\q closes the window \u2014 the service carries on",
    "running, and your rows are still in the data directory.",
    "",
    "Run \\conninfo inside psql to see the connection you are",
    "using: database, user, host, port, and your Backend PID \u2014",
    "the server gives every connection its own process.",
]
ny = 848
for line in notes:
    if line:
        d.text((1024, ny), fit(line, f_small, 490, "note line"), font=f_small, fill=MUTED)
    ny += 21

# ------------------------------------------- takeaways
cards = [
    ("The server is the database.", "One long-running service, started by Windows at boot."),
    ("psql is a client, not the database.", "It holds no data. It only asks and prints."),
    ("Your rows are files on disk.", "In the data directory \u2014 not inside psql."),
]
cx = 60
for head, body in cards:
    panel((cx, 1050, cx + 466, 1130), fill=PANEL, r=12)
    d.rounded_rectangle((cx, 1050, cx + 5, 1130), radius=2, fill=ACCENT)
    d.text((cx + 26, 1068), fit(head, f_take_h, 420, "takeaway head"), font=f_take_h, fill=INK)
    d.text((cx + 26, 1094), fit(body, f_take_b, 420, "takeaway body"), font=f_take_b, fill=MUTED)
    cx += 490

d.text((70, 1162),
       "Names and paths shown are the standard Windows installer defaults. "
       "On your own PC:  Get-Service postgresql*  \u2014 if it lists nothing, your server was started by hand "
       "(pg_ctl start) and nothing restarts it for you.",
       font=f_foot, fill=FAINT)

img.save(OUT)
print(f"wrote {OUT}  {W}x{H}")
if problems:
    print("OVERFLOW WARNINGS:")
    for p in problems:
        print("  -", p)
else:
    print("no text overflow")
