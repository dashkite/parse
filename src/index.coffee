
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
    if (p = rest.indexOf x) >= 0
      value: x
      rest: rest[p..]
    else
      error:
        expected: x
        got: rest[..10]

match = (p) ->
  (c) -> {c..., (p c)...}

skip = (p) ->
  (c) ->
    if !(m = p c).error?
      {rest} = m
      {c..., rest}
    else
      {c..., m...}

all = (fx) ->
  (c) ->
    d = c
    value = []
    for f in fx
      if !(m = f d).error?
        value.push m.value if m.value?
        d = {d..., m..., value}
      else
        # todo: handle error based on where we got
        return {c..., m...}

any = (fx) ->
  (c) ->
    for f in fx
      if !(m = f c).error?
        return {c..., m...}
    {c..., m...}

many = (f) ->
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

pipe = (fx) ->
  (c) ->
    d = c
    for f in fx
      if (d = f d).error?
        return d
    d

list = (del, f) ->
  all [
    skip del
    f
  ]

between = (args...) ->
  [ d1, d2, f ] = switch args.length
    when 1 then throw new ArgumentError "between: needs 2 arguments"
    when 2 then [ args[0], args[0], args[1] ]
    else args
  all [
    skip d1
    f
    skip d2
  ]

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
      throw new Error "parse error: expected #{expected}, got '#{got}'"
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
  pipe
  list
  between
  tag
  merge
  forward
  parser
}
