# Usage Guides

This document provides recipes for using Parse to accomplish common tasks.

## Creating a simple arithmetic parser

Parsing arithmetic expressions involves combining pattern matching and custom transformations to extract values and perform calculations.

Parse provides the `all` function to sequence a series of patterns and the `map` function to transform the resulting values into a final outcome. You can define lexical tokens like digits and operators using `re` and handle whitespace with `trim` and `ws`.

```coffeescript
import * as p from "@dashkite/parse"

parse = p.parser p.pipe [

  p.all [
    p.re /^\d+/, "digit"
    p.trim p.ws
    p.re /^(\+|-)/, "operator"
    p.trim p.ws
    p.re /^\d+/, "digit"
  ]

  p.map ([left, operator, right]) ->
  
    leftNum = Number.parseInt left, 10
    rightNum = Number.parseInt right, 10

    # process the given operation
    switch operator
      when "+" then leftNum + rightNum
      when "-" then leftNum - rightNum
]

# check to see if it works
assert.equal 8, parse "5 + 3"
```

1. Define a pipeline using `pipe` to sequence parsing rules and data transformations.
2. Use `all` to specify a sequence of token matchers. Match the first digit using a regular expression pattern.
3. Allow for whitespace using `trim` on `ws`, ensuring it does not appear in the resulting context.
4. Match the arithmetic operator using a regular expression pattern.
5. Provide a transformation function using `map` to convert the string digits into numerical types.
6. Return the computed result based on the captured operator.

## Parsing a delimited list

Processing comma-separated values or function arguments requires matching repetitive token patterns cleanly.

Parse provides the `list` combinator to simplify this process. By supplying a delimiter pattern and an item pattern, you can quickly accumulate multiple values into an array without manual iteration.

```coffeescript
import * as p from "@dashkite/parse"

# match a list of digits separated by commas
parseList = p.parser p.list (p.text ","), (p.re /^\d+/, "digit")

# process the extracted list values
list = parseList "1,2,3,4"
```

1. Use the `list` pattern function to define a repeating sequence.
2. Supply the delimiter pattern as the first argument, such as a comma.
3. Supply the item pattern as the second argument, representing the actual data tokens you want to extract.
4. The parser automatically iterates through the input and returns the matched items as a JavaScript array.

## Parsing recursive structures

Languages like JSON feature nested, repeating hierarchies (such as arrays within arrays) that require recursive definitions.

Parse allows you to define recursive grammars using the `forward` function, breaking cyclic dependencies in JavaScript. The `between` function cleanly manages the opening and closing brackets of the recursive structures.

```coffeescript
import * as p from "@dashkite/parse"

# forward reference for a recursive array definition
arrayParser = p.forward -> nestedArray

# match a single digit or another nested array
element = p.any [
  p.re /^\d+/, "digit"
  arrayParser
]

# define a list of elements surrounded by brackets
nestedArray = p.between [ (p.text "["), (p.text "]") ], 
  p.list (p.text ","), element

parseNested = p.parser nestedArray

# parse the nested structure
result = parseNested "[1,[2,3],4]"
```

1. Declare a `forward` function that returns the overarching grammar rule, deferring its evaluation.
2. Define the individual elements, which can either be raw values or the recursive grammar itself using `any`.
3. Use the `between` function to denote the start and end boundary tokens (e.g., brackets).
4. Combine this with the `list` function to repeatedly match elements separated by delimiters within the brackets.

## Building a structured object (AST)

Instead of returning raw arrays of strings, parsers often need to produce structured Abstract Syntax Trees (ASTs) or configuration objects for downstream systems.

Parse provides the `tag` and `merge` actions to construct structured objects on the fly. You can tag individual matches with specific keys and then merge them into a single cohesive object context.

```coffeescript
import * as p from "@dashkite/parse"

parseConfig = p.parser p.pipe [
  p.all [
    p.pipe [
      p.re /^\w+/, "key"
      p.tag "key"
    ]
    p.trim (p.text "=")
    p.pipe [
      p.re /^\w+/, "value"
      p.tag "value"
    ]
  ]
  p.merge
]

# returns { key: "host", value: "localhost" }
config = parseConfig "host=localhost"
```

1. Use `pipe` to sequence the pattern matching and data transformations.
2. After matching a token, use `tag` to map the matched value to a specific property key.
3. Trim out formatting characters, such as the equals sign, so they are not included in the final context.
4. Call `merge` at the end of the sequence to compress the tagged array elements into a single structured object.

## Managing context state

Context-sensitive grammars, such as XML, require the parser to "remember" previously matched values (like an opening tag name) to correctly match future values (like a closing tag name).

Parse exposes `set` and `get` to interact with custom data properties on the parser context, allowing creators to store and recall state dynamically.

```coffeescript
import * as p from "@dashkite/parse"

parseElement = p.parser p.pipe [
  p.all [
    # match opening tag and save the name
    p.trim (p.text "<")
    p.pipe [
      p.re /^\w+/, "tag name"
      p.set "currentTag"
    ]
    p.trim (p.text ">")
    
    # match content
    p.re /^[^<]+/, "content"
    
    # match closing tag using the saved name
    p.trim (p.text "</")
    p.pipe [
      p.get "currentTag"
      p.apply p.text
    ]
    p.trim (p.text ">")
  ]
]

# parse a matching symmetric tag
element = parseElement "<title>Hello</title>"
```

1. Match the opening tag name and immediately use `set` to store its value under a custom state property.
2. Process the inner contents of the element.
3. When reaching the closing tag, use `get` to retrieve the previously saved tag name.
4. Pass the retrieved string to `apply` to dynamically parameterize the `text` pattern, enforcing that the closing tag explicitly matches the opening tag.
