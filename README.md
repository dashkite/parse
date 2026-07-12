# Parse

*A parser combinator library for JavaScript, written in CoffeeScript*

[![Hippocratic License HL3-CORE](https://img.shields.io/static/v1?label=Hippocratic%20License&message=HL3-CORE&labelColor=5e2751&color=bc8c3d)](https://firstdonoharm.dev/version/3/0/core.html)

Parse is an expression grammar parser combinator library. It provides the building blocks to construct stateful recursive descent parsers with backtracking and lookahead.

## Features

- Fully-featured stateful recursive descent parser
- Backtracking with lookahead
- Customizable error handling
- Approximately 2kb compressed

## Installation

```shell
pnpm install @dashkite/parse
```

Use with your preferred bundler or loader.

## Usage

A simple expression grammar written using Parse:

```coffeescript
import * as p from "@dashkite/parse"

parse = p.parser p.pipe [

  # match all of the following in sequence...

  p.all [
    # match a regexp for a digit
    p.re /^\d+/, "digit"

    # allow whitespace but don't save it
    p.trim p.ws

    # match an operator
    p.re /^(\+|-)/, "operator"

    # allow whitespace
    p.trim p.ws

    # second digit
    p.re /^\d+/, "digit"
  ]

  # take the results and do something
  p.map ([x, op, y]) ->
  
    # convert the text digits to actual numbers
    x = Number.parseInt x, 10
    y = Number.parseInt y, 10

    # process the given operation
    switch op
      when "+" then x + y
      when "-" then x - y
]

# check to see if it works
assert.equal 8, parse "5 + 3"
assert.equal 2, parse "5 - 3"

assert.throws (-> parse "7 + a"),
  message: "parse error: expected digit, got 'a'"
```

## Other Resources

- [Usage Guides](docs/recipes.md)
- [Reference Documentation](docs/reference.md)
- [Technical Notes](docs/technical-notes.md)
- [Testing](docs/testing.md)
