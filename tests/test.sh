#!/usr/bin/env bash
# Verifier entrypoint. Harbor uploads tests/ to /tests/ after the agent runs,
# then executes this script. It grades /app/sheet.py and writes a scalar reward
# to /logs/verifier/reward.txt.
set -uo pipefail

mkdir -p /logs/verifier

if ! python3 /tests/grade.py; then
    echo "grader crashed; scoring 0" >&2
    echo "0.0" > /logs/verifier/reward.txt
fi

echo "reward.txt: $(cat /logs/verifier/reward.txt)"
