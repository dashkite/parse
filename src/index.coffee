
re = (x, expected) ->
  ({rest}) ->
    if (m = (rest.match x))?
      value: m[0]
      rest: rest[(m.index + m[0].length)..]
    else
      error:
        expected: expected ? x.toString()
        got: rest[..10]

word = re /^\w+/, "word"

ws = re /^\s+/, "whitespace"

text = (x) ->
  ({rest}) ->
    if rest[..(x.length - 1)] == x
      value: x
      rest: rest[(x.length)..]
    else
      error:
        expected: "'#{x}'"
        got: rest[..10]

pattern = (x) ->
  if x.constructor == String
    text x
  else if x.constructor == RegExp
    re x
  else x

match = (x) ->
  f = pattern x
  (c) -> {c..., (f c)...}

skip = (x) ->
  f = pattern x
  (c) ->
    if !(m = f c).error?
      {rest} = m
      {c..., rest, value: undefined}
    else
      {c..., m..., value: undefined}

all = (fx) ->
  (c) ->
    d = c
    value = []
    for f in fx
      if !(m = f d).error?
        value.push m.value if m.value?
        d = {d..., m..., value}
      else
        return {c..., m...}
    d

any = (fx) ->
  (c) ->
    for f in fx
      if !(m = f c).error?
        return {c..., m...}
    {c..., m...}

many = (x) ->
  f = pattern x
  (c) ->
    d = c
    value = []
    while d.rest.length > 0
      if !(m = f d).error?
        value.push m.value if m.value?
        d = {d..., m..., value}
      else
        return d
    return d

optional = (x) ->
  f = pattern x
  (c) ->
    if !(m = f c).error?
      {c..., m...}
    else
      {c..., value: undefined}

pipe = (fx) ->
  (c) ->
    d = c
    for f in fx
      if (d = f d).error?
        return d
    d

map = (f) -> (c) -> {c..., value: (f c.value)}

test = (name, f) ->
  (c) ->
    if f c
      c
    else
      error:
        expected: name
        got: c.value

list = (del, x) ->
  f = pattern x
  pipe [
    all [
      many all [
        f
        skip del
      ]
      f
    ]
    map (ax) -> ax.flat 2
  ]

between = (args...) ->
  [ d1, d2, f ] = switch args.length
    when 1 then throw new ArgumentError "between: needs 2 arguments"
    when 2 then [ args[0], args[0], args[1] ]
    else args

  pipe [
    all [
      skip d1
      f
      skip d2
    ]
    map ([value]) -> value
  ]

trim = (x) -> skip optional x

tag = (key) -> map (value) -> [key]: value

merge = (key) -> map (value) -> Object.assign {}, value...

forward = (f) -> (c) -> f() c

parser = (f) ->
  (s) ->
    m = f
      original: s
      rest: s
      data: {}
    if m.error?
      {expected, got} = m.error
      # TODO compute line-number and position
      # 1. find position
      # 2. count the newlines up until that position
      # 3. count characters until the first newline prior to position
      got = if got == "" then "end of string" else "'#{got}'"
      throw new Error "parse error: expected #{expected}, got #{got}"
    else if m.rest.length > 0
      throw new Error "parse error:
        expected end of input, got '#{m.rest[..10]}'"
    else
      m.value

export {
  re
  word
  ws
  text
  match
  skip
  all
  any
  many
  optional
  pipe
  map
  test
  list
  between
  trim
  tag
  merge
  forward
  parser
}
