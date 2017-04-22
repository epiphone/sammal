# sammal

A toy Lisp interpreter for a compilers class.

## Dependencies

- [Elixir 1.4](http://elixir-lang.org/install.html)

## Build

```bash
mix escript.build
./sammal
```

## Test

```bash
mix test
```

## TODO

- handle empty after quote `x'`
- quasiquote
- disallow special chars in symbols
- string interpolation
- range operations? `0..10`, `0..-1`, ...
- macros
