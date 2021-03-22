# Parse

*A parser combinator library for JavaScript, written in CoffeeScript*

A simple expression grammer written using Parse:

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
]

# check to see if it works
assert.equal 8, parse "5 + 3"
assert.equal 2, parse "5 - 3"

assert.throws (-> parse "7 + a"),
  message: "parse error: expected digit, got 'a'"
```

## Features

- Fully-featured stateful recursive descent parser
- Backtracking with lookahead and memoization
- Customizable error handling
- Approximately 2kb compressed

## Install

```
npm i @dashkite/parse
```

Use with your preferred bundler or loader.

## Reference

Almost all functions in Parse take and return a parsing context. A parsing context contains the current parse state, which includes the original input, the remaining input, custom data, and either a value or error.

There are two main types of functions: pattern and action. Pattern functions, referred to simply as patterns when parameterized, consume input and produce value or errors. Action functions don’t consumer input, but modify the parsing context in other ways. For example, the `test` function takes a predicate and applies it to the parsing context value. If the predicate returns true, the context is returned unchanged. Otherwise, it adds an error object to the context, which will short-circuit functions like `all`.

The main exception is `parser` which accepts a parsing context and returns its value if there’s no error and no remaining input.

### Pattern Functions

Use to consume input and produce values or errors. Typically used within higher-level pattern functions like  `all`, `any`, or `list`.

| Name      | Arguments            | Description                                                  |
| --------- | -------------------- | ------------------------------------------------------------ |
| re        | expression, name     | Matches the given regular expression. The expression should almost always be anchored to the start of the input with the `^` operator. Provide an optional *name* to produce more meaningful error messages. |
| word      | -                    | Matches a word. Convenience function for `re /^\w+/, "word"` |
| ws        | -                    | Matches whitespace, not including newlines. Convenience function for `re /^[ \t]+/s, "whitespace"` |
| text      | text string          | Matches the given text string.                               |
| skip      | pattern              | Matches the given pattern, but discards the matched value.   |
| eof       | -                    | Matches the end of the input.                                |
| eol       | -                    | Matches the end of the line or input.                        |
| all       | array                | Matches all of the patterns in the given array. The resulting values are placed into an array. |
| any       | array                | Attempts to match each of the patterns in the given array until a match is found. |
| many      | pattern              | Keeps matching the given pattern until it fails, return the matched values as an array. |
| optional  | pattern              | Attempts to match the given pattern, but on failure, returns the original parsing context unchanged. |
| lookahead | pattern              | Attempts to match the given pattern. If successful, returns the original context unchanged. Use to short-circuit parsing to avoid backtracking. |
| list      | delimiter, item      | Attempts to match a list of the given *item* pattern, delimited by the *delimiter* pattern. |
| between   | open, close, pattern | Attempts to match the given pattern after matching *open* and then matching *close*. If no *close* pattern is provided, uses *open* again. |
| trim      | pattern              | Matches the given string, discarding the matched value. On failure, returns the original context unchanged. Equivalent to `skip optional pattern`. |
| forward   | function             | Matches the pattern returned by the given function. Use to avoid circular dependencies by forward-referencing patterns that haven’t yet been defined. |
| apply     | pattern function     | Parameterizes the given pattern function using the value of the current context and attempts a match. |

### Action Functions

Use to manipulate the parsing context to manage custom state or transform the value. Typically used within `pipe`.

| Name    | Arguments           | Description                                                  |
| ------- | ------------------- | ------------------------------------------------------------ |
| map     | transform           | Passes the context value into the given *transform* function and returning a new context with the returned value. |
| flatten | -                   | Does a shallow (depth of one) array flatten on the context value. |
| first   | -                   | Returns the first element of the context value.              |
| last    | -                   | Returns the last element of the context value.               |
| test    | name, predicate     | Passes the context value into the given *predicate* function. If the predicate returns true, the context is returned unchanged. Otherwise, a new context is produced with an error using the given *name*. |
| tag     | key                 | Return the context value as an object with the given property *key*. Use in conjunction with `merge` to build up objects during parsing. |
| merge   | -                   | Merge an array of objects as the context value into a single object. |
| set     | key, value          | Set the custom state of the parser for a given property *key* to *value*. If *value* is not given, the property is set to the context value. |
| get     | key                 | Gets the given custom state property and sets it as the context value. |
| push    | key, value, pattern | Pushes the given *value* onto a stack defined by the custom state property *key* and attempts to match the pattern. Pops the stack and returns the result of the attempted match. |
| pipe    | array               | Attempts to match all of the given patterns but short-circuits if any produce an error. Does not directly modify the context value (unlike `all`, which accumulates the matched patterns into an array). Use to build up a sequence of actions. |

