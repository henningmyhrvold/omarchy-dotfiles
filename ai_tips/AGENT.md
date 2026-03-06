# Project: Python Calculator

## Tech Stack
- Language: Python 3.12+
- Package manager: uv (at /usr/bin/uv or ~/.local/bin/uv)
- Test framework: pytest
- Linting: ruff
- Type hints: required on all public functions

## Project Structure

```
python-calculator/
├── src/
│   └── calculator/
│       ├── __init__.py        ← export public API
│       ├── core.py            ← arithmetic functions
│       └── cli.py             ← CLI entry point
├── tests/
│   ├── __init__.py
│   └── test_core.py           ← all unit tests go here
├── pyproject.toml
├── plan.json                  ← task list (do not delete)
├── PROMPT.md                  ← Ralph's instructions (do not edit)
├── CLAUDE.md                  ← this file
├── activity.md                ← append-only iteration log
└── README.md
```

## Commands
- Initialize environment: `uv sync`
- Run tests: `python -m pytest tests/ -v`
- Run tests with coverage: `python -m pytest tests/ -v --cov=src/calculator --cov-report=term-missing`
- Run CLI: `python -m calculator <op> <a> <b>`
- Lint: `ruff check src/`

## CLI Interface

The CLI is invoked as: `python -m calculator <operation> <num1> <num2>`

Operations: `add`, `sub`, `mul`, `div`

Examples:
```
python -m calculator add 2 3     → outputs: 5.0
python -m calculator sub 10 4    → outputs: 6.0
python -m calculator mul 3 4     → outputs: 12.0
python -m calculator div 10 2    → outputs: 5.0
python -m calculator div 10 0    → outputs error to stderr, exits with code 1
```

Output format: ONLY the numeric result on stdout. Nothing else.

## pyproject.toml Structure

```toml
[project]
name = "calculator"
version = "0.1.0"
requires-python = ">=3.12"

[project.scripts]
calculator = "calculator.cli:main"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.pytest.ini_options]
testpaths = ["tests"]

[tool.coverage.run]
source = ["src/calculator"]

[dependency-groups]
dev = [
    "pytest>=8.0",
    "pytest-cov>=5.0",
    "ruff>=0.4",
]
```

## Function Signatures

```python
# src/calculator/core.py

def add(a: float, b: float) -> float: ...
def subtract(a: float, b: float) -> float: ...
def multiply(a: float, b: float) -> float: ...
def divide(a: float, b: float) -> float: ...  # raises ZeroDivisionError if b == 0
```

## Error Handling
- Division by zero: raise ZeroDivisionError (Python built-in, not a custom exception)
- Invalid CLI args: print error to stderr, sys.exit(1)
- Invalid number format from CLI: print "Error: invalid number" to stderr, sys.exit(1)

## Git Conventions
- Commit after each completed task
- Message format: `feat: <description>` or `test: <description>` or `docs: <description>`
- NEVER commit with failing tests or failing ruff checks
