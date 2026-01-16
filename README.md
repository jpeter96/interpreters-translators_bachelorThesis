# LOOP, WHILE, GOTO Interpreters and Translators

Interpreters for three languages from computability theory and translators between them.

## Setup

```bash
npm install
npm run build
npm link        # enables 'lang' command
```

## Usage

```bash
lang <file> [options]
```

Place your `.loop`, `.while`, and `.goto` files in the `examples/` folder. Language is detected from `.language` ending.

### Options

| Flag | Description |
|------|-------------|
| `-x0=5` | Set initial variable (overrides program) |
| `-t2while`, `-t2w` | Translate to WHILE |
| `-t2goto`, `-t2g` | Translate to GOTO |
| `-verify` | Run both, compare results |
| `-verbose` | Show execution steps |

## Examples

### Run a program

```bash
lang multiply_input.loop -x0=3 -x1=4
```

### Translate

```bash
lang multiply_input.loop -t2while       # LOOP -> WHILE
lang multiply_input.loop -t2goto        # LOOP -> GOTO (via WHILE)
lang divide.while -t2goto               # WHILE -> GOTO
lang countdown.goto -t2while            # GOTO -> WHILE
```

### Verify translation

```bash
lang divide.while -t2goto -verify -verbose
```

## Language Syntax

### LOOP

```
x0 := 5;
x1 := 0;
LOOP x0 DO
    x1 := x1 + 1;
END
```

### WHILE

```
x0 := 10;
WHILE x0 != 0 DO
    x0 := x0 - 1;
END
```

Conditions: `=`, `!=`, `<`, `>`, `<=`, `>=`

### GOTO

```
x0 := 5;
M1: IF x0 = 0 THEN GOTO M2;
    x0 := x0 - 1;
    GOTO M1;
M2: HALT;
```

## Project Structure

```
src/
  lexer.ts          Shared tokenizer
  loop/             LOOP (AST, parser, interpreter)
  while/            WHILE (AST, parser, interpreter)
  goto/             GOTO (AST, parser, interpreter)
  translators/      Translators between languages
  cli.ts            CLI
examples/           Sample programs
```

## Translators

- LOOP -> WHILE (direct)
- LOOP -> GOTO (via WHILE)
- WHILE -> GOTO (direct)
- GOTO -> WHILE (direct)

This demonstrates: LOOP ⊆ WHILE = GOTO
