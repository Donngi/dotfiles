#!/usr/bin/env python3
"""Claude Code statusLine"""
import json, os, re, shutil, subprocess, sys

# --- Constants ---

R = '\033[0m'
DIM = '\033[2m'
GRAY = '\033[38;2;60;60;60m'
BRANCH_COLOR = '\033[38;2;230;218;166m'

SEP = f' {GRAY}│{R} '
SEP_WIDTH = 3  # visible width of " │ "
LABEL_W = 3  # ctx/5h/7d ラベルを揃えるための固定幅

LEVEL_COLORS = [
    (50, (0, 200, 80)),      # green  (0-49%)
    (75, (255, 182, 42)),     # orange (50-74%)
    (100, (255, 0, 0)),       # red    (75-100%)
]


# --- Helpers ---

def rgb(r, g, b):
    return f'\033[38;2;{r};{g};{b}m'


def level_rgb(pct):
    for threshold, c in LEVEL_COLORS:
        if pct < threshold:
            return c
    return LEVEL_COLORS[-1][1]


def visible_len(s):
    return len(re.sub(r'\033\[[^m]*m', '', s))


def pad(s, width):
    return s + ' ' * max(0, width - visible_len(s))


def truncate_plain(s, width):
    if len(s) <= width:
        return s
    if width <= 0:
        return ''
    if width == 1:
        return '…'
    return s[: width - 1] + '…'


def fmt_tokens(n):
    if n is None or n == 0:
        return '0'
    if n >= 1_000_000:
        return f'{n / 1_000_000:.1f}M'
    if n >= 1_000:
        return f'{n / 1_000:.1f}k'
    return str(n)


def fmt_bar(label, pct, width=10):
    label = label.ljust(LABEL_W)
    p = round(pct)
    pct_clamped = min(max(pct, 0), 100)
    full = round(pct_clamped * width / 100)
    rest = width - full
    r, g, b = level_rgb(pct)
    c = rgb(r, g, b)
    cd = rgb(int(r * 0.4), int(g * 0.4), int(b * 0.4))
    filled = f'{c}{"█" * full}{R}'
    empty = f'{cd}{"⣿" * rest}{R}' if rest else ''
    return f'{label} {filled}{empty} {c}{p}%{R}'


def build_hr(segs):
    parts = ['─' * visible_len(s) for s in segs]
    if len(parts) <= 1:
        return f'{GRAY}{parts[0] if parts else ""}{R}'
    # 最後のジョイントは ┼（1行目パイプと接続）、それ以外は ┬
    result = parts[0]
    for i in range(1, len(parts)):
        joint = '┼' if i == len(parts) - 1 else '┬'
        result += f'─{joint}─{parts[i]}'
    return f'{GRAY}{result}──{R}'


def row_width(segs):
    return sum(visible_len(s) for s in segs) + SEP_WIDTH * max(0, len(segs) - 1)


# --- Data extraction ---

COLS = shutil.get_terminal_size((80, 24)).columns

data = json.load(sys.stdin)

model = data.get('model', {}).get('display_name', 'Claude')
cwd = data.get('workspace', {}).get('current_dir', '')

branch = ''
if cwd:
    try:
        branch = subprocess.check_output(
            ['git', '-C', cwd, '--no-optional-locks', 'symbolic-ref', '--short', 'HEAD'],
            stderr=subprocess.DEVNULL,
        ).decode().strip()
    except Exception:
        pass

dir_full = ''
if cwd:
    home = os.path.expanduser('~')
    d = cwd.replace(home, '~', 1)
    parts = d.split('/')
    dir_full = '/'.join(parts[-2:]) if len(parts) > 2 else d

ctx = data.get('context_window', {})
ctx_pct = ctx.get('used_percentage')
in_fmt = fmt_tokens(ctx.get('total_input_tokens'))
out_fmt = fmt_tokens(ctx.get('total_output_tokens'))

rate_limits = data.get('rate_limits') or {}
five_pct = rate_limits.get('five_hour', {}).get('used_percentage')
week_pct = rate_limits.get('seven_day', {}).get('used_percentage')

# --- Build base segments ---

ctx_bar = fmt_bar('ctx', ctx_pct if ctx_pct is not None else 0)
tokens = f'{DIM}in:{R}{in_fmt} {DIM}out:{R}{out_fmt}'
ctx_tokens = f'{ctx_bar} {tokens}'

five_bar = fmt_bar('5h', five_pct) if five_pct is not None else ''
week_bar = fmt_bar('7d', week_pct) if week_pct is not None else ''


def dir_branch_plain_len(dir_s):
    if branch and dir_s:
        return len(dir_s) + 1 + len(branch)
    if branch:
        return len(branch)
    return len(dir_s)


# --- Mode selection ---

full_segs = [s for s in [ctx_tokens, five_bar, week_bar] if s]
no_tok_segs = [s for s in [ctx_bar, five_bar, week_bar] if s]

line1_plain_w = dir_branch_plain_len(dir_full) + SEP_WIDTH + len(model)

# build_hr は末尾に `──` (2 文字) を付けるため、行本体より 2 文字広くなる
HR_EXTRA = 2

if row_width(full_segs) + HR_EXTRA <= COLS and line1_plain_w <= COLS:
    mode = 'full'
elif row_width(no_tok_segs) + HR_EXTRA <= COLS and line1_plain_w <= COLS:
    mode = 'no_tokens'
else:
    mode = 'fold'

# --- Compose dir_branch (shorten dir in fold mode if needed) ---

dir_display = dir_full
if mode == 'fold':
    # 罫線が overflow しないように、line1 の目標幅は COLS - HR_EXTRA
    target = COLS - HR_EXTRA
    if dir_branch_plain_len(dir_display) + SEP_WIDTH + len(model) > target:
        path_parts = dir_full.split('/')
        if len(path_parts) > 1:
            dir_display = path_parts[-1]
    if dir_branch_plain_len(dir_display) + SEP_WIDTH + len(model) > target:
        budget = target - SEP_WIDTH - len(model)
        if branch:
            budget -= 1 + len(branch)
        dir_display = truncate_plain(dir_display, max(0, budget))

if branch and dir_display:
    dir_branch = f'{dir_display} {BRANCH_COLOR}{branch}{R}'
elif branch:
    dir_branch = f'{BRANCH_COLOR}{branch}{R}'
else:
    dir_branch = dir_display

# --- Output ---

if mode in ('full', 'no_tokens'):
    first_col = ctx_tokens if mode == 'full' else ctx_bar
    line3_segs = [s for s in [first_col, five_bar, week_bar] if s]

    col1_w = visible_len(first_col)
    col2_w = visible_len(five_bar)
    col_last_w = max(visible_len(week_bar), visible_len(model))

    if line3_segs:
        line3_segs[-1] = pad(line3_segs[-1], col_last_w)

    line1_segs = [
        pad(dir_branch, col1_w + SEP_WIDTH + col2_w),
        pad(model, col_last_w),
    ]

    print(SEP.join(line1_segs))
    print(build_hr(line3_segs))
    print(SEP.join(line3_segs))
else:
    # Fold モード: dir/branch │ model の下に各バーを 1 行ずつ縦積み
    print(f'{dir_branch}{SEP}{model}')
    print(build_hr([dir_branch, model]))
    for bar in [ctx_bar, five_bar, week_bar]:
        if bar:
            print(bar)
