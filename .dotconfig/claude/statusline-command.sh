#!/usr/bin/env python3
"""Claude Code statusLine（汎用 + AI-DLC 統合）

AI-DLC ワークフロー進行中（aidlc-docs/aidlc-state.md が存在）のプロジェクトでは、
汎用ブロックの下に区切り罫線 + Stage 行 + Agent 行を追加する。列幅変数を汎用版と
共有して描くため、PHASE 前の │ は必ず汎用版の境界（7d/model の前の桁）に一致する。
"""
import glob, json, os, re, shutil, subprocess, sys

# --- Constants ---

R = '\033[0m'
GRAY = '\033[38;2;60;60;60m'
BRANCH_COLOR = '\033[38;2;230;218;166m'
TEAL_RGB = (36, 171, 153)   # AI-DLC アクセント #24AB99
DIM_RGB = (120, 120, 120)   # AI-DLC サポート/レビュアー

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


def fmt_bar_na(label):
    # rate_limit が無い環境（Bedrock 等）用。バー本体は描かず、
    # ラベル + グレーの N/A を表示する（欠落 = 適用外）。
    return f'{label.ljust(LABEL_W)} {rgb(*DIM_RGB)}N/A{R}'


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


# --- AI-DLC helpers ---

AIDLC_STAGE_DISPLAY = {
    'workspace-scaffold': 'Workspace Scaffold', 'workspace-detection': 'Workspace Detection',
    'state-init': 'State Init', 'intent-capture': 'Intent Capture',
    'market-research': 'Market Research', 'feasibility': 'Feasibility',
    'scope-definition': 'Scope Definition', 'team-formation': 'Team Formation',
    'rough-mockups': 'Rough Mockups', 'approval-handoff': 'Approval & Handoff',
    'reverse-engineering': 'Reverse Engineering', 'practices-discovery': 'Practices Discovery',
    'requirements-analysis': 'Requirements Analysis', 'user-stories': 'User Stories',
    'refined-mockups': 'Refined Mockups', 'application-design': 'Application Design',
    'units-generation': 'Units Generation', 'delivery-planning': 'Delivery Planning',
    'functional-design': 'Functional Design', 'nfr-requirements': 'NFR Requirements',
    'nfr-design': 'NFR Design', 'infrastructure-design': 'Infrastructure Design',
    'code-generation': 'Code Generation', 'build-and-test': 'Build and Test',
    'ci-pipeline': 'CI Pipeline', 'deployment-pipeline': 'Deployment Pipeline',
    'environment-provisioning': 'Env Provisioning', 'deployment-execution': 'Deployment Execution',
    'observability-setup': 'Observability Setup', 'incident-response': 'Incident Response',
    'performance-validation': 'Performance Validation', 'feedback-optimization': 'Feedback & Optimization',
}


def aidlc_color(s, rgb_tuple):
    r, g, b = rgb_tuple
    return f'{rgb(r, g, b)}{s}{R}'


def aidlc_bar(done, total, width=10):
    # 汎用 fmt_bar と同じグリフ（█ 点灯 / ⣿ 消灯）でティール 1 色
    full = min(width, (done * width) // total) if total and total > 0 else 0
    rest = width - full
    r, g, b = TEAL_RGB
    c = rgb(r, g, b)
    cd = rgb(int(r * 0.4), int(g * 0.4), int(b * 0.4))
    filled = f'{c}{"█" * full}{R}' if full else ''
    empty = f'{cd}{"⣿" * rest}{R}' if rest else ''
    return filled + empty


def aidlc_field(text, label):
    m = re.search(r'^-\s*\*\*' + re.escape(label) + r'\*\*:[^\S\n]*([^\n]*)', text, re.M)
    return m.group(1).replace('\r', '').strip() if m else ''


def aidlc_phase_progress(text, phase):
    parts = phase.split()
    token = parts[0].upper() if parts else ''
    if not token:
        return 0, 0
    in_phase = False
    done = total = 0
    for line in text.splitlines():
        if line.startswith('### ') and f'{token} PHASE' in line.upper():
            in_phase = True
            continue
        if line.startswith('### '):
            in_phase = False
        if not in_phase or not line.startswith('- ['):
            continue
        if 'SKIP' in line or '[S]' in line:
            continue
        total += 1
        if line.startswith('- [x]'):
            done += 1
    return done, total


def aidlc_agent_map(project_dir):
    m = {'orchestrator': 'Orchestrator'}
    for path in glob.glob(os.path.join(project_dir, '.claude', 'agents', '*.md')):
        try:
            t = open(path, encoding='utf-8').read()
        except OSError:
            continue
        nm = re.search(r'^name:\s*(.+)$', t, re.M)
        dn = re.search(r'^display_name:\s*(.+)$', t, re.M)
        if nm and dn:
            m[nm.group(1).strip()] = dn.group(1).strip()
    return m


def aidlc_stage_roster(project_dir, slug):
    if not slug:
        return None, [], None
    matches = glob.glob(os.path.join(project_dir, '.claude', 'aidlc-common', 'stages', '**', f'{slug}.md'), recursive=True)
    if not matches:
        return None, [], None
    try:
        text = open(matches[0], encoding='utf-8').read()
    except OSError:
        return None, [], None
    fm = text.split('---', 2)[1] if text.startswith('---') else text
    lead = re.search(r'^lead_agent:\s*(.+)$', fm, re.M)
    lead = lead.group(1).strip() if lead else None
    reviewer = re.search(r'^reviewer:\s*(.+)$', fm, re.M)
    reviewer = reviewer.group(1).strip() if reviewer else None
    support = []
    lines = fm.splitlines()
    for i, line in enumerate(lines):
        mm = re.match(r'^support_agents:\s*(.*)$', line)
        if not mm:
            continue
        val = mm.group(1).strip()
        if val and val != '[]':
            support = [val]
        elif val == '':
            for nxt in lines[i + 1:]:
                m2 = re.match(r'^\s+-\s*(\S+)', nxt)
                if m2:
                    support.append(m2.group(1).strip())
                elif re.match(r'^\S', nxt):
                    break
        break
    return lead, support, reviewer


def aidlc_strip_agent(name):
    return name[:-6] if name.endswith(' Agent') else name


def load_aidlc(project_dir):
    if not project_dir:
        return None
    state_path = os.path.join(project_dir, 'aidlc-docs', 'aidlc-state.md')
    if not os.path.isfile(state_path):
        return None
    try:
        text = open(state_path, encoding='utf-8').read()
    except OSError:
        return None
    phase = aidlc_field(text, 'Lifecycle Phase')
    if not phase:
        return None
    status = aidlc_field(text, 'Status')
    a = {
        'phase': phase,
        'stage': aidlc_field(text, 'Current Stage'),
        'next': aidlc_field(text, 'Next Stage'),
        'active': aidlc_field(text, 'Active Agent'),
        'complete': status in ('Completed', 'Complete'),
    }
    a['done'], a['total'] = aidlc_phase_progress(text, phase)
    a['lead'], a['support'], a['reviewer'] = aidlc_stage_roster(project_dir, a['stage'])
    a['amap'] = aidlc_agent_map(project_dir)
    return a


def aidlc_line_phase(a):
    # 1 行目: Phase: <PHASE> <bar> <ratio>
    out = f"{aidlc_color('Phase:', TEAL_RGB)} {a['phase']}"
    bar = aidlc_bar(a['done'], a['total'])
    if bar:
        out += f' {bar}'
    if a['total'] > 0:
        out += ' ' + aidlc_color('%d/%d' % (a['done'], a['total']), TEAL_RGB)
    return out


def aidlc_line_stage(a):
    # 2 行目: Stage: <現> - Next: <次>
    disp = AIDLC_STAGE_DISPLAY.get(a['stage'], a['stage'])
    out = f"{aidlc_color('Stage:', TEAL_RGB)} {disp}"
    nxt = a.get('next')
    if nxt:
        nxt_disp = AIDLC_STAGE_DISPLAY.get(nxt, nxt)
        out += f" {GRAY}-{R} {aidlc_color('Next:', DIM_RGB)} {aidlc_color(nxt_disp, DIM_RGB)}"
    return out


def aidlc_agent_line(a):
    # 3 行目: Agent: <lead> +<support> *<reviewer>
    roster = []
    if a['lead']:
        roster.append((a['lead'], '', None))
    elif a['active']:
        roster.append((a['active'], '', None))
    for s in a['support']:
        roster.append((s, '+', DIM_RGB))
    if a['reviewer']:
        roster.append((a['reviewer'], '*', DIM_RGB))
    if not roster:
        return ''
    chunks = []
    for slug, prefix, base in roster:
        label = prefix + aidlc_strip_agent(a['amap'].get(slug, slug))
        chunks.append(aidlc_color(label, base) if base else label)
    return f"{aidlc_color('Agent:', TEAL_RGB)} " + ' '.join(chunks)


def build_hr_up(segs):
    # 汎用テーブルの底罫線: ┴ が上のバー行の │ に上方接続する（下には繋がない）。
    segs = [s for s in segs if s]
    if not segs:
        return ''
    parts = ['─' * visible_len(s) for s in segs]
    res = parts[0]
    for i in range(1, len(parts)):
        res += f'─┴─{parts[i]}'
    return f'{GRAY}{res}──{R}'


def aidlc_rows_wide(a, line3_segs):
    # 3 行構成: Phase / Stage(+Next) / Agent。上の区切りはバー行の │ に ┴ で接続、
    # Agent の下に上端と同じ長さのプレーン罫線を引いてブロックを閉じる。
    if a['complete']:
        return [aidlc_color('COMPLETE', TEAL_RGB) + ' ' + aidlc_bar(1, 1)]
    top = build_hr_up(line3_segs)
    rows = [top, aidlc_line_phase(a), aidlc_line_stage(a)]
    agent = aidlc_agent_line(a)
    if agent:
        rows.append(agent)
    rows.append(f'{GRAY}{"─" * visible_len(top)}{R}')
    return rows


def aidlc_rows_fold(a, dir_branch):
    # 折りたたみ時はプレーンな区切り線 + 3 行 + 下端罫線。
    if a['complete']:
        return [aidlc_color('COMPLETE', TEAL_RGB) + ' ' + aidlc_bar(1, 1)]
    phase_l = aidlc_line_phase(a)
    stage_l = aidlc_line_stage(a)
    agent_l = aidlc_agent_line(a)
    w = max(visible_len(phase_l), visible_len(stage_l), visible_len(agent_l))
    rule = f'{GRAY}{"─" * w}{R}'
    rows = [rule, phase_l, stage_l]
    if agent_l:
        rows.append(agent_l)
    rows.append(rule)
    return rows


# --- Data extraction ---

COLS = shutil.get_terminal_size((80, 24)).columns

data = json.load(sys.stdin)

model = data.get('model', {}).get('display_name', 'Claude')
# モデル名の右に effort（推論強度）を付与。非対応モデルでは effort 自体が absent。
_effort = (data.get('effort') or {}).get('level', '')
if _effort:
    model = f"{model} {GRAY}·{R} {rgb(*DIM_RGB)}{_effort}{R}"
cwd = data.get('workspace', {}).get('current_dir', '')

project_dir = data.get('workspace', {}).get('project_dir') or cwd
aidlc = load_aidlc(project_dir)

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

rate_limits = data.get('rate_limits') or {}
five_pct = rate_limits.get('five_hour', {}).get('used_percentage')
week_pct = rate_limits.get('seven_day', {}).get('used_percentage')

# --- Build base segments ---

ctx_bar = fmt_bar('ctx', ctx_pct if ctx_pct is not None else 0)

five_bar = fmt_bar('5h', five_pct) if five_pct is not None else fmt_bar_na('5h')
week_bar = fmt_bar('7d', week_pct) if week_pct is not None else fmt_bar_na('7d')


def dir_branch_plain_len(dir_s):
    if branch and dir_s:
        return len(dir_s) + 1 + len(branch)
    if branch:
        return len(branch)
    return len(dir_s)


# --- Mode selection ---

wide_segs = [s for s in [ctx_bar, five_bar, week_bar] if s]

line1_plain_w = dir_branch_plain_len(dir_full) + SEP_WIDTH + visible_len(model)

# build_hr は末尾に `──` (2 文字) を付けるため、行本体より 2 文字広くなる
HR_EXTRA = 2

if row_width(wide_segs) + HR_EXTRA <= COLS and line1_plain_w <= COLS:
    mode = 'wide'
else:
    mode = 'fold'

# --- Compose dir_branch (shorten dir in fold mode if needed) ---

dir_display = dir_full
if mode == 'fold':
    # 罫線が overflow しないように、line1 の目標幅は COLS - HR_EXTRA
    target = COLS - HR_EXTRA
    if dir_branch_plain_len(dir_display) + SEP_WIDTH + visible_len(model) > target:
        path_parts = dir_full.split('/')
        if len(path_parts) > 1:
            dir_display = path_parts[-1]
    if dir_branch_plain_len(dir_display) + SEP_WIDTH + visible_len(model) > target:
        budget = target - SEP_WIDTH - visible_len(model)
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

if mode == 'wide':
    first_col = ctx_bar
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
    if aidlc:
        for _ln in aidlc_rows_wide(aidlc, line3_segs):
            print(_ln)
else:
    # Fold モード: dir/branch │ model の下に各バーを 1 行ずつ縦積み
    print(f'{dir_branch}{SEP}{model}')
    print(build_hr([dir_branch, model]))
    for bar in [ctx_bar, five_bar, week_bar]:
        if bar:
            print(bar)
    if aidlc:
        for _ln in aidlc_rows_fold(aidlc, dir_branch):
            print(_ln)
