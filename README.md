# Inquiri (inqr)

A single-file bash/awk log failure aggregator. Point it at a log file and get
a fast breakdown of what's failing, when, and how badly — no dependencies
beyond `gawk`.

```
$ inqr app.log -t 5 -w 15m
TOP FAILURES
────────────────────────────────────────────────
    99  Permission denied
    95  Disk full
    90  Authentication failed
    82  Failed to connect to database
    81  Request timeout

TIME WINDOW       FAILURES
──────────────────────────────
10:00–10:15          30
10:15–10:30          30
10:30–10:45          30
...
```

## Install

```bash
git clone https://github.com/ed-dz/inquiri.git
cd inqr
chmod +x inqr
sudo cp inqr /usr/local/bin/inqr   # optional, puts it on your PATH
```

Requires **gawk** (GNU awk). On Debian/Ubuntu: `sudo apt install gawk`.
(macOS ships BSD awk by default — install gawk via `brew install gawk`.)

## Usage

```
inqr <logfile> [options]

  -t, --top N            Show top N failure types                 (default: 10)
  -w, --window SIZE      Time bucket size: 5m|15m|30m|60m|24h|day  (default: 15m)
      --since DURATION   Incident-summary mode over the trailing DURATION
                          (e.g. 30m, 24h, 7d)
      --breakdown        Per-window x per-failure-type table
      --patterns FILE    Extra classification rules (see below)
  -h, --help
  -v, --version
```

### Modes

**Default (report) mode** — Top Failures list, plus total failure counts per
time window:

```bash
inqr /var/log/app.log -t 10 -w 15m
```

**Breakdown mode** — Same time buckets, but broken out per failure type:

```bash
inqr app.log --breakdown --window 15m
```

```
TIME             FAILURE                         COUNT
────────────────────────────────────────────────────────
10:00-10:15      Connection refused                 3
                 Permission denied                  1
                 Timeout connecting                 1

10:15-10:30      Connection refused                47
                 Timeout connecting                 12
                 Disk full                           2
```

**Incident summary mode** (`--since`) — the full picture: period, totals,
top failures, a trend line at your chosen window, newly-appearing failure
types, and spike detection:

```bash
inqr app.log --since 24h
```

```
LOG FAILURE SUMMARY
══════════════════════════════════════════════
Period:        2026-09-21 20:00 -> 2026-09-22 20:00
Total errors:  18421
Failure types: 8
...
TREND — 15M BUCKETS
──────────────────────────────────────────────
20:00   12
20:15   17
...
10:45   392  <- spike

NEW FAILURES
──────────────────────────────────────────────
11:02  Connection pool exhausted

SPIKES
──────────────────────────────────────────────
Connection refused       +382% at 10:45
```

A failure type counts as "new" if it first appears in the second half of the
period. A bucket is flagged as a spike (in the trend) when it's at least
150% higher than the previous bucket; the same threshold drives the
per-failure-type spike list. Both are currently fixed constants at the top
of the script (`SPIKE_THRESHOLD`) — edit the script if you want a different
sensitivity.

## How failures are detected and grouped

A line is treated as a candidate failure if it matches (case-insensitively):

```
error|fail|denied|timeout|timed out|refused|exception|unauthorized|
unreachable|disk full|no space left|panic|fatal|dropped|reset by peer|
unavailable|critical
```

Matching lines are then classified into a canonical label using an ordered
list of built-in rules (e.g. "refused" → `Connection refused`, "permission
denied" → `Permission denied`). Anything that doesn't match a known rule
falls back to a generic normalizer that strips timestamps, IPs, UUIDs,
quoted strings, and numbers so that near-identical lines still group
together, e.g.:

```
Failed to write chunk 4821 to /tmp/upload_9f1c.dat
Failed to write chunk 77 to /tmp/upload_a02e.dat
```
both become `Failed to write chunk # to /tmp/upload_<uuid>.dat`.

### Custom classification rules

Your logs will have failure messages this script has never seen. Add your
own rules with `--patterns FILE`, one rule per line, tab-separated:

```
<extended-regex>\t<label>
```

Example (`myrules.conf`):

```
payment gateway.*(declined|rejected)	Payment declined
could not acquire lock	Lock contention
```

```bash
inqr app.log --patterns myrules.conf --since 12h
```

Custom rules are checked before the built-in ones, in the order they appear
in the file.

## Timestamp formats

`inqr` recognizes:
- ISO 8601: `2026-09-22 10:15:32` or `2026-09-22T10:15:32`
- Syslog: `Sep 22 10:15:32` (year assumed to be the current year)

Lines it can't timestamp are still counted in the Top Failures list, but
can't be placed into a time bucket.

## Testing it out

A synthetic sample log with a deliberate spike and a late-appearing failure
type is included at `test/sample.log`:

```bash
./inqr test/sample.log --since 3h -w 15m
```

## License

MIT — see [LICENSE](LICENSE).
