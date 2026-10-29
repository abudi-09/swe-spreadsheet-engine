# Your task

Implement `evaluate(cells)` in `sheet.py`. The full contract is in the task
instructions. This file is a quick reference plus one worked example.

## Example

Input:

```python
cells = {
    "A1": "10",
    "A2": "20",
    "A3": "=A1+A2",
    "B1": "=SUM(A1:A3)",
    "B2": "=B1/0",
    "B3": "=BADREF(",
    "C1": "=C2",
    "C2": "=C1",
}
```

Expected `evaluate(cells)`:

```python
{
    "A1": 10.0,
    "A2": 20.0,
    "A3": 30.0,
    "B1": 60.0,       # 10 + 20 + 30
    "B2": "#DIV/0!",  # division by zero
    "B3": "#ERROR!",  # malformed formula
    "C1": "#CYCLE!",  # C1 and C2 reference each other
    "C2": "#CYCLE!",
}
```

Run `python3 public_example.py` to check your implementation against this
example. Passing it is necessary but **not** sufficient — the held-out grading
uses more sheets.
