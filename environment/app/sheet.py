def evaluate(cells):
    """Evaluate a spreadsheet.

    Args:
        cells: dict mapping a cell name (e.g. "A1") to its raw string content.
               Content beginning with "=" is a formula; otherwise it is a
               numeric literal ("" means 0).

    Returns:
        dict mapping every input cell name to its computed value: a float, or
        one of the error strings "#DIV/0!", "#CYCLE!", "#ERROR!".

    See /app/README.md for the full contract and /app/public_example.py for a
    runnable example.
    """
    raise NotImplementedError("implement evaluate()")
