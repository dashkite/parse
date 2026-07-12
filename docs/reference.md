# Reference Documentation

Almost all functions in Parse take and return a parsing context. A parsing context contains the current parse state, which includes the original input, the remaining input, custom data, and either a value or error.

There are two main types of functions: pattern and action. Pattern functions consume input and produce values or errors. Action functions don't consume input but modify the parsing context in other ways.

## parser

$parser: context \to value$

Accepts a parsing context and returns its value if there’s no error and no remaining input.

## Pattern Functions

Use to consume input and produce values or errors. Typically used within higher-level pattern functions like `all`, `any`, or `list`.

### re

$re: expression, name \to pattern$

Matches the given regular expression. The expression should almost always be anchored to the start of the input with the `^` operator. Provide an optional name to produce more meaningful error messages.

### word

$word: \to pattern$

Matches a word. Convenience function for `re /^\w+/, "word"`.

### ws

$ws: \to pattern$

Matches whitespace, not including newlines. Convenience function for `re /^[ \t]+/s, "whitespace"`.

### text

$text: string \to pattern$

Matches the given text string.

### skip

$skip: pattern \to pattern$

Matches the given pattern, but discards the matched value.

### eof

$eof: \to pattern$

Matches the end of the input.

### eol

$eol: \to pattern$

Matches the end of the line or input.

### all

$all: array \to pattern$

Matches all of the patterns in the given array. The resulting values are placed into an array.

### any

$any: array \to pattern$

Attempts to match each of the patterns in the given array until a match is found.

### many

$many: pattern \to pattern$

Keeps matching the given pattern until it fails, return the matched values as an array.

### optional

$optional: pattern \to pattern$

Attempts to match the given pattern, but on failure, returns the original parsing context unchanged.

### lookahead

$lookahead: pattern \to pattern$

Attempts to match the given pattern. If successful, returns the original context unchanged. Use to short-circuit parsing to avoid backtracking.

### list

$list: delimiter, item \to pattern$

Attempts to match a list of the given item pattern, delimited by the delimiter pattern.

### between

$between: open, close, pattern \to pattern$

Attempts to match the given pattern after matching open and then matching close. If no close pattern is provided, uses open again.

### trim

$trim: pattern \to pattern$

Matches the given string, discarding the matched value. On failure, returns the original context unchanged. Equivalent to `skip optional pattern`.

### forward

$forward: function \to pattern$

Matches the pattern returned by the given function. Use to avoid circular dependencies by forward-referencing patterns that haven’t yet been defined.

### apply

$apply: function \to pattern$

Parameterizes the given pattern function using the value of the current context and attempts a match.

## Action Functions

Use to manipulate the parsing context to manage custom state or transform the value. Typically used within `pipe`.

### map

$map: transform \to pattern$

Passes the context value into the given transform function and returning a new context with the returned value.

### flatten

$flatten: \to pattern$

Does a shallow (depth of one) array flatten on the context value.

### first

$first: \to pattern$

Returns the first element of the context value.

### last

$last: \to pattern$

Returns the last element of the context value.

### test

$test: name, predicate \to pattern$

Passes the context value into the given predicate function. If the predicate returns true, the context is returned unchanged. Otherwise, a new context is produced with an error using the given name.

### tag

$tag: key \to pattern$

Return the context value as an object with the given property key. Use with `merge` to build up objects during parsing.

### merge

$merge: \to pattern$

Merge an array of objects as the context value into a single object.

### append

$append: skey, pattern \to pattern$

Match the given pattern and append the resulting value to the context value, or to custom data using the optional skey.

### assign

$assign: skey, key, pattern \to pattern$

Match the given pattern and assign the resulting value to the context value property key, or to custom data using the optional skey.

### preserve

$preserve: pattern \to pattern$

Match pattern but keep the original context value. Use with `append` or `assign` to build up a result using the context value rather than custom data.

### set

$set: key, value \to pattern$

Set the custom state of the parser for a given property key to value. If value is not given, the property is set to the context value.

### get

$get: key \to pattern$

Gets the given custom state property and sets it as the context value.

### push

$push: key, value, pattern \to pattern$

Pushes the given value onto a stack defined by the custom state property key and attempts to match the pattern. Pops the stack and returns the result of the attempted match.

### pipe

$pipe: array \to pattern$

Attempts to match all of the given patterns but short-circuits if any produce an error. Does not directly modify the context value. Use to build up a sequence of actions.
