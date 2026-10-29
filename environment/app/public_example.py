"""Self-check for the public example. Run: python3 public_example.py

This is a convenience for the agent, not the grader. The real grading runs
held-out sheets that are not in this environment.
"""
from sheet import evaluate

CELLS = {
    "A1": "10", "A2": "20", "A3": "=A1+A2",
    "B1": "=SUM(A1:A3)", "B2": "=B1/0", "B3": "=BADREF(",
    "C1": "=C2", "C2": "=C1",
}

EXPECTED = {
    "A1": 10.0, "A2": 20.0, "A3": 30.0,
    "B1": 60.0, "B2": "#DIV/0!", "B3": "#ERROR!",
    "C1": "#CYCLE!", "C2": "#CYCLE!",
}


def _match(exp, act):
    if isinstance(exp, str):
        return isinstance(act, str) and act.strip() == exp.strip()
    return isinstance(act, (int, float)) and abs(float(act) - exp) <= 1e-6


def main():
    got = evaluate(CELLS)
    ok = 0
    for cell, exp in EXPECTED.items():
        act = got.get(cell)
        flag = "ok " if _match(exp, act) else "XX "
        if flag == "ok ":
            ok += 1
        print("%s %-3s expected=%-9r got=%r" % (flag, cell, exp, act))
    print("\n%d/%d cells correct" % (ok, len(EXPECTED)))


if __name__ == "__main__":
    main()
