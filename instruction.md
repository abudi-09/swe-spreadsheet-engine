# Spreadsheet formula evaluation engine

Implement a spreadsheet calculation engine from scratch, in Python, in the file
`/app/sheet.py`.

## The API you must implement

`sheet.py` must define one function:

```python
def evaluate(cells: dict) -> dict:
    ...
```

`cells` maps a **cell name** (an uppercase column part + a row number, e.g.
`"A1"`, `"B12"`, `"AA3"`) to its **raw content** as a string. Your function must
return a dict mapping **every input cell** to its computed value.

## Cell content

- A content string that begins with `=` is a **formula**.
- Any other non-empty content is a **numeric literal** (parsed as a float). A
  literal that does not parse as a number evaluates to the error `#ERROR!`.
- The empty string `""` evaluates to `0.0`. A cell **referenced but not present**
  in `cells` is also treated as `0.0`.

## Formula grammar

```
expr   := term (("+" | "-") term)*
term   := factor (("*" | "/") factor)*
factor := NUMBER | CELLREF | FUNC "(" args ")" | "(" expr ")" | "-" factor | "+" factor
args   := arg ("," arg)*
arg    := CELLREF ":" CELLREF        # a rectangular range
        | expr
```

- `CELLREF` is case-insensitive (`a1` == `A1`).
- Whitespace between tokens is insignificant.
- Supported functions: `SUM`, `AVG`, `MIN`, `MAX`, `COUNT` (case-insensitive).
- A range `A1:B2` expands to the full rectangle between the two corners
  (`A1, A2, B1, B2`), in any corner order.

### Function semantics (over the cells a range/args resolve to)

- `SUM`  — sum of values; cells that are empty/undefined count as `0`.
- `COUNT`— number of **defined, numeric** cells (empty/undefined are not counted).
- `AVG`  — (sum of defined numeric cells) / (count of defined numeric cells);
  if that count is `0`, the result is `#DIV/0!`.
- `MIN` / `MAX` — over the defined numeric cells; if there are none, `#ERROR!`.

## Values and errors

Numeric results are Python `float`s. The three error values are the exact
strings:

- `#DIV/0!` — division by zero (`x / 0`), or `AVG`/`COUNT` with no numeric cells.
- `#CYCLE!` — the cell is part of a circular reference (e.g. `A1 = =B1`,
  `B1 = =A1`).
- `#ERROR!` — a malformed formula, an unknown function, or a non-numeric literal.

Errors **propagate**: any arithmetic or function that reads an error value
yields that same error value (the first one encountered).

## Rules

- Pure Python 3.11 standard library only. No network, no third-party packages.
- Do not try to read the grader, the hidden test sheets, or any expected
  answers — they are not present in your environment while you work.
- You are scored only on the behavior of `evaluate`, by running it on held-out
  sheets. Partial credit is per-cell.

A runnable example with expected output is in `/app/README.md` and
`/app/public_example.py` (run `python3 /app/public_example.py`).
