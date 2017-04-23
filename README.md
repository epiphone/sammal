# sammal

A toy Lisp interpreter for a compilers class.

## Dependencies

- [Elixir 1.4](http://elixir-lang.org/install.html)

## Build

```bash
mix escript.build
./sammal [-c "(some command)"] [-i] [./some_source_file.sammal]
```

## Test

```bash
mix test
```

## TODO

- fix tokenizing "\x\"y"
- file IO
- REPL
- handle empty after quote `x'`
- error reporting
- quasiquote
- disallow special chars in symbols
- string interpolation
- range operations? `0..10`, `0..-1`, ...
- macros
