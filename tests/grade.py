"""Grader. Imports the agent's /app/sheet.py, runs it on the held-out sheets
in this directory, and writes a scalar reward (fraction of correct cells) to
/logs/verifier/reward.txt.
"""
import json
import os
import sys

TESTS_DIR = os.path.dirname(os.path.abspath(__file__))
APP_DIR = "/app"
REWARD_DIR = "/logs/verifier"
REWARD_FILE = os.path.join(REWARD_DIR, "reward.txt")

sys.path.insert(0, APP_DIR)


def _is_num(x):
    return isinstance(x, (int, float)) and not isinstance(x, bool)


def _matches(expected, actual):
    if isinstance(expected, str):
        return isinstance(actual, str) and actual.strip() == expected.strip()
    return _is_num(actual) and abs(float(actual) - float(expected)) <= 1e-6


def _write(score):
    os.makedirs(REWARD_DIR, exist_ok=True)
    with open(REWARD_FILE, "w") as f:
        f.write("%.6f\n" % score)
    print("%.6f" % score)


def main():
    with open(os.path.join(TESTS_DIR, "ground_truth.json")) as f:
        ground = json.load(f)
    sheets_dir = os.path.join(TESTS_DIR, "sheets")

    try:
        import sheet
    except Exception as e:  # agent code missing or unimportable
        sys.stderr.write("could not import /app/sheet.py: %r\n" % e)
        _write(0.0)
        return

    total = correct = 0
    for name, expected in ground.items():
        total += len(expected)
        with open(os.path.join(sheets_dir, name + ".json")) as f:
            cells = json.load(f)
        try:
            result = sheet.evaluate(cells)
        except Exception as e:
            sys.stderr.write("sheet %s: evaluate raised %r\n" % (name, e))
            continue
        if not isinstance(result, dict):
            sys.stderr.write("sheet %s: evaluate did not return a dict\n" % name)
            continue
        for cell, exp in expected.items():
            if _matches(exp, result.get(cell)):
                correct += 1

    score = (correct / total) if total else 0.0
    sys.stderr.write("%d/%d cells correct\n" % (correct, total))
    _write(max(0.0, min(1.0, score)))


if __name__ == "__main__":
    main()
