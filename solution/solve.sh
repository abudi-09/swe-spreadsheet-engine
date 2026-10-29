#!/usr/bin/env bash
# Reference solution: writes a correct engine to /app/sheet.py.
# The oracle agent runs this; the verifier then scores /app/sheet.py.
set -euo pipefail
mkdir -p /app
cat > /app/sheet.py <<'PYEOF'
"""Reference spreadsheet formula evaluation engine.

Public API: evaluate(cells) -> dict

`cells` maps a cell name (e.g. "A1") to its raw string content. A content
string that starts with "=" is a formula; otherwise it is a literal (a number,
or the empty string meaning 0). The return value maps every input cell to its
computed value: a float, or one of the error strings "#DIV/0!", "#CYCLE!",
"#ERROR!".
"""

import re

_ERR_DIV0 = "#DIV/0!"
_ERR_CYCLE = "#CYCLE!"
_ERR = "#ERROR!"

_CELL_RE = re.compile(r'^[A-Za-z]+[0-9]+$')
_SPLIT_RE = re.compile(r'^([A-Za-z]+)([0-9]+)$')

_FUNCS = {"SUM", "AVG", "MIN", "MAX", "COUNT"}


# ---------------------------------------------------------------- lexer ----
def _tokenize(s):
    toks = []
    i, n = 0, len(s)
    while i < n:
        c = s[i]
        if c.isspace():
            i += 1
            continue
        if c in '+-*/(),:':
            toks.append((c, c))
            i += 1
            continue
        if c.isdigit() or c == '.':
            j = i
            while j < n and (s[j].isdigit() or s[j] == '.'):
                j += 1
            toks.append(('NUM', s[i:j]))
            i = j
            continue
        if c.isalpha():
            j = i
            while j < n and s[j].isalnum():
                j += 1
            toks.append(('IDENT', s[i:j]))
            i = j
            continue
        raise ValueError("bad character %r" % c)
    toks.append(('EOF', None))
    return toks


# --------------------------------------------------------------- parser ----
class _Parser:
    def __init__(self, toks):
        self.toks = toks
        self.p = 0

    def peek(self):
        return self.toks[self.p]

    def nxt(self):
        t = self.toks[self.p]
        self.p += 1
        return t

    def expect(self, kind):
        t = self.nxt()
        if t[0] != kind:
            raise ValueError("expected %s, got %s" % (kind, t[0]))
        return t

    def parse(self):
        node = self.expr()
        if self.peek()[0] != 'EOF':
            raise ValueError("trailing tokens")
        return node

    def expr(self):
        node = self.term()
        while self.peek()[0] in ('+', '-'):
            op = self.nxt()[0]
            node = ('bin', op, node, self.term())
        return node

    def term(self):
        node = self.factor()
        while self.peek()[0] in ('*', '/'):
            op = self.nxt()[0]
            node = ('bin', op, node, self.factor())
        return node

    def factor(self):
        t = self.peek()
        if t[0] == '-':
            self.nxt()
            return ('neg', self.factor())
        if t[0] == '+':
            self.nxt()
            return self.factor()
        if t[0] == '(':
            self.nxt()
            node = self.expr()
            self.expect(')')
            return node
        if t[0] == 'NUM':
            self.nxt()
            return ('num', float(t[1]))
        if t[0] == 'IDENT':
            self.nxt()
            if self.peek()[0] == '(':
                name = t[1].upper()
                if name not in _FUNCS:
                    raise ValueError("unknown function %r" % name)
                self.nxt()  # (
                args = []
                if self.peek()[0] != ')':
                    args.append(self.arg())
                    while self.peek()[0] == ',':
                        self.nxt()
                        args.append(self.arg())
                self.expect(')')
                return ('func', name, args)
            if not _CELL_RE.match(t[1]):
                raise ValueError("bad cell ref %r" % t[1])
            return ('cell', t[1].upper())
        raise ValueError("unexpected token %s" % (t,))

    def arg(self):
        t = self.peek()
        if (t[0] == 'IDENT' and _CELL_RE.match(t[1])
                and self.toks[self.p + 1][0] == ':'):
            c1 = self.nxt()[1].upper()
            self.nxt()  # :
            t2 = self.nxt()
            if t2[0] != 'IDENT' or not _CELL_RE.match(t2[1]):
                raise ValueError("bad range end")
            return ('range', c1, t2[1].upper())
        return ('expr', self.expr())


# ------------------------------------------------------------- ranges ------
def _col_to_num(col):
    n = 0
    for ch in col:
        n = n * 26 + (ord(ch.upper()) - ord('A') + 1)
    return n


def _num_to_col(n):
    s = ""
    while n > 0:
        n, r = divmod(n - 1, 26)
        s = chr(ord('A') + r) + s
    return s


def _split_cell(ref):
    m = _SPLIT_RE.match(ref)
    return m.group(1).upper(), int(m.group(2))


def _expand_range(c1, c2):
    col1, row1 = _split_cell(c1)
    col2, row2 = _split_cell(c2)
    a, b = sorted((_col_to_num(col1), _col_to_num(col2)))
    r1, r2 = sorted((row1, row2))
    out = []
    for cc in range(a, b + 1):
        for rr in range(r1, r2 + 1):
            out.append(_num_to_col(cc) + str(rr))
    return out


# ---------------------------------------------------------- evaluation -----
def evaluate(cells):
    raw = {}
    for k, v in cells.items():
        raw[k.upper()] = "" if v is None else str(v)

    asts = {}
    values = {}
    state = {}

    def get_ast(cell):
        if cell in asts:
            return asts[cell]
        content = raw.get(cell, "")
        if content.startswith("="):
            try:
                ast = _Parser(_tokenize(content[1:])).parse()
            except Exception:
                ast = ('errlit', _ERR)
        else:
            ast = None
        asts[cell] = ast
        return ast

    def literal_value(cell):
        content = raw.get(cell, "")
        if content == "":
            return 0.0
        try:
            return float(content)
        except ValueError:
            return _ERR

    def eval_cell(cell):
        if cell in values:
            return values[cell]
        if state.get(cell) == 'visiting':
            return _ERR_CYCLE
        ast = get_ast(cell)
        if ast is None:
            v = literal_value(cell)
            values[cell] = v
            state[cell] = 'done'
            return v
        state[cell] = 'visiting'
        v = eval_node(ast)
        values[cell] = v
        state[cell] = 'done'
        return v

    def eval_node(node):
        t = node[0]
        if t == 'num':
            return node[1]
        if t == 'errlit':
            return node[1]
        if t == 'cell':
            return eval_cell(node[1])
        if t == 'neg':
            v = eval_node(node[1])
            return v if isinstance(v, str) else -v
        if t == 'bin':
            _, op, l, r = node
            lv = eval_node(l)
            if isinstance(lv, str):
                return lv
            rv = eval_node(r)
            if isinstance(rv, str):
                return rv
            if op == '+':
                return lv + rv
            if op == '-':
                return lv - rv
            if op == '*':
                return lv * rv
            if op == '/':
                return _ERR_DIV0 if rv == 0 else lv / rv
        if t == 'func':
            _, name, args = node
            collected = []  # (value, defined)
            for a in args:
                if a[0] == 'range':
                    for c in _expand_range(a[1], a[2]):
                        cv = eval_cell(c)
                        if isinstance(cv, str):
                            return cv
                        collected.append((cv, raw.get(c, "") != ""))
                else:
                    cv = eval_node(a[1])
                    if isinstance(cv, str):
                        return cv
                    collected.append((cv, True))
            allv = [v for v, _d in collected]
            defv = [v for v, d in collected if d]
            if name == 'SUM':
                return float(sum(allv))
            if name == 'COUNT':
                return float(len(defv))
            if name == 'AVG':
                return _ERR_DIV0 if not defv else float(sum(defv) / len(defv))
            if name == 'MIN':
                return _ERR if not defv else float(min(defv))
            if name == 'MAX':
                return _ERR if not defv else float(max(defv))
        return _ERR

    out = {}
    for orig in cells.keys():
        out[orig] = eval_cell(orig.upper())
    return out
PYEOF
echo "reference solution installed at /app/sheet.py"
