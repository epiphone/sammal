# sammal

A toy Lisp interpreter for a compilers class.

## Dependencies

- [Elixir 1.4](http://elixir-lang.org/install.html)

## Build

```bash
mix deps.get
mix escript.build
./sammal [-c "(some command)"] [-i] [./some_source_file.sammal]

# Examples:
./sammal -c "(def multiply (x y) (* x y)) (display (multiply 2 3))"
```

## Test

```bash
mix test
```

## TODO

- [x] quoting
- [ ] fix tokenizing "\x\"y"
- [ ] file IO
- [ ] REPL
- [ ] handle empty after quote `x'`
- [x] error reporting
- [ ] quasiquote
- [ ] disallow special chars in symbols
- [ ] string interpolation
- [ ] range operations? `0..10`, `0..-1`, ...
- [ ] macros
