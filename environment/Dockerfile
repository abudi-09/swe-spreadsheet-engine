FROM python:3.11-slim

WORKDIR /app

# Starter workspace the agent sees: the stub to implement, plus a readable
# contract and a runnable self-check. The grader and hidden sheets are NOT in
# this image; Harbor uploads tests/ to /tests/ only after the agent finishes.
COPY app/ /app/

CMD ["sleep", "infinity"]
