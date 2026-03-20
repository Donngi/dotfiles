#!/usr/bin/env python3
"""Claude Code statusLine"""
import json, os, re, subprocess, sys

# --- Constants ---

R = '\033[0m'
DIM = '\033[2m'
GRAY = '\033[38;2;60;60;60m'
BRANCH_COLOR = '\033[38;2;230;218;166m'

SEP = f' {GRAY}│{R} '
SEP_WIDTH = 3  # visible width of " │ "

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


def fmt_tokens(n):
    if n is None or n == 0:
        return '0'
    if n >= 1_000_000:
        return f'{n / 1_000_000:.1f}M'
    if n >= 1_000:
        return f'{n / 1_000:.1f}k'
    return str(n)


def fmt_bar(label, pct, width=10):
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


# --- Data extraction ---

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

dir_display = ''
if cwd:
    home = os.path.expanduser('~')
    d = cwd.replace(home, '~', 1)
    parts = d.split('/')
    dir_display = '/'.join(parts[-2:]) if len(parts) > 2 else d

ctx = data.get('context_window', {})
ctx_pct = ctx.get('used_percentage')
in_fmt = fmt_tokens(ctx.get('total_input_tokens'))
out_fmt = fmt_tokens(ctx.get('total_output_tokens'))

rate_limits = data.get('rate_limits') or {}
five_pct = rate_limits.get('five_hour', {}).get('used_percentage')
week_pct = rate_limits.get('seven_day', {}).get('used_percentage')

# --- Build segments ---

# Line 3: [ctx + tokens] │ [5h] │ [7d]
ctx_bar = fmt_bar('ctx', ctx_pct) if ctx_pct is not None else ''
tokens = f'{DIM}in:{R}{in_fmt} {DIM}out:{R}{out_fmt}'
ctx_tokens = f'{ctx_bar} {tokens}' if ctx_bar else tokens

five_bar = fmt_bar('5h', five_pct) if five_pct is not None else ''
week_bar = fmt_bar('7d', week_pct) if week_pct is not None else ''

line3_segs = [s for s in [ctx_tokens, five_bar, week_bar] if s]

# Column widths (line 3 drives alignment)
col1_w = visible_len(ctx_tokens)
col2_w = visible_len(five_bar)
col3_w = max(visible_len(week_bar), visible_len(model))

# Pad last segment to col3 width
if line3_segs:
    line3_segs[-1] = pad(line3_segs[-1], col3_w)

# Line 1: [dir + branch] │ [model]
dir_branch = dir_display
if branch:
    dir_branch = f'{dir_display} {BRANCH_COLOR}{branch}{R}' if dir_display else f'{BRANCH_COLOR}{branch}{R}'

line1_segs = [
    pad(dir_branch, col1_w + SEP_WIDTH + col2_w),
    pad(model, col3_w),
]

# --- Output ---

print(SEP.join(line1_segs))
print(build_hr(line3_segs))
print(SEP.join(line3_segs))
