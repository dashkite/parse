inspect = (s) -> JSON.stringify s

re = (x, expected) ->
  (c) ->
    if (m = (c.rest.match x))?
      {c...
      value: m[0]
      rest: c.rest[(m.index + m[0].length)..]}
    else
      {c...
      error:
        expected: expected ? inspect x
        got: c.rest}

word = re /^\w+/, "word"

digits = re /^\d+/

ws = re /^[ \t]+/s, "whitespace"

text = (x) ->
  (c) ->
    if c.rest[..(x.length - 1)] == x
      {c...
      value: x
      rest: c.rest[(x.length)..]}
    else
      {c...
      error:
        expected: inspect x
        got: c.rest}

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
      {c..., m...}

negate = (x, expected) ->
  f = pattern x
  (c) ->
    if (m = f c).error?
      value = c.rest[0]
      rest = c.rest[1..]
      {c..., value, rest }
    else
      {
        c..., 
        error:
          expected: expected ? inspect x
          got: c.rest
      }

eof = (c) ->
  if (c.rest.length == 0)
    c
  else
    {c...
    error:
      expected: "end of input"
      got: c.rest}

eol = re /^(\n|$)/, "end of line"

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

sequence = (delimiter, fx) ->
  [ gx..., k ] = fx
  hx = (all [ ( pattern g ), (skip delimiter) ] for g in gx)
  pipe [
    all [ hx..., ( pattern k ) ]
    flatten
  ]

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
        break
    if value.length > 0
      {d..., value}
    else if m?
      {d..., m...}
    else
      {
        d...,
        error:  
          expected: inspect x
          got: "[end of input]"
      }

optional = (x) ->
  f = pattern x
  (c) ->
    if !(m = f c).error?
      {c..., m...}
    else
      {c..., value: undefined}

lookahead = (x, expected) ->
  f = pattern x
  (c) ->
    if !(m = f c).error?
      c
    else
      {c...
      error:
        expected: expected ? inspect x
        got: c.rest}

pipe = (fx) ->
  (c) ->
    d = c
    for f in fx
      if (d = f d).error?
        return d
    d

map = (f) -> (c) -> {c..., value: (f c.value)}

_flatten = (ax) ->
  if Array.isArray ax
    result = []
    for x in ax
      y = _flatten x
      if Array.isArray y
        result = result.concat y
      else
        result.push y
    result
  else
    ax

flatten = map (ax) -> _flatten ax

first = map (ax) -> ax[0]

last = map (ax) -> ax[ ax.length - 1 ]

test = (name, f) ->
  (c) ->
    if f c.value
      c
    else
      {c...
      error:
        expected: name
        got: inspect c.value }

testContext = (name, f) ->
  (c) ->
    if f c
      c
    else
      {
        c...
        error:
          expected: name
          got: c.rest
      }

list = (d, x) ->
  f = pattern x
  d = pattern d
  pipe [
    all [
      f
      optional many pipe [
        all [
          skip d
          f
        ]
        first
      ]
    ]
    map ([first, rest ]) ->
      [ first, rest... ]
  ]

between = (args...) ->
  [ d1, d2, f ] = switch args.length
    when 1 then throw new Error "between: needs 2 arguments"
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

merge = (c) ->
  r = {}
  for _tag in c.value
    for key, value of _tag
      if r[key]?
        if Array.isArray r[key]
          r[key].push value
        else
          r[key] = [ value ]
      else
        r[key] = value
  c.value = r
  c

cat = map (ax) -> ax.join ""

append = (args...) ->
  switch args.length
    when 1 then _appendValue args...
    when 2 then _appendData args...
    else throw new Error "append: needs 1 or 2 arguments"

_appendValue = (x) ->
  f = pattern x
  (c) ->
    if !(m = f c).error?
      value = if c.value?
        if Array.isArray c.value
          [ c.value..., m.value ]
        else
          [ c.value, m.value ]
      else
        [ m.value ]
      {m..., value}
    else m

_appendData = (skey, x) ->
  f = pattern x
  (c) ->
    if !(m = f c).error?
      data = {m.data...}
      data[skey] = if c.data[skey]?
        if Array.isArray c.data[skey]
          [ c.data[skey]..., m.value ]
        else
          [ c.data[skey], m.value ]
      else
        [ m.value ]
      {m..., data}
    else m

assign = (args...) ->
  switch args.length
    when 2 then _assignValue args...
    when 3 then _assignData args...
    else throw new Error "append: needs 2 or 3 arguments"

_assignValue = (key, x) ->
  f = pattern x
  (c) ->
    if !(m = f c).error?
      value = if c.value?
        {c.value..., [key]: m.value}
      else
        [key]: m.value
      {m..., value}
    else m

_assignData = (skey, key, x) ->
  f = pattern x
  (c) ->
    if !(m = f c).error?
      data = {m.data...}
      data[skey] = if c.data[skey]?
        {c.data[skey]..., [key]: m.value}
      else
        [key]: m.value
      {m..., data}
    else m

assignData = (object) ->
  (c) -> Object.assign c.data, object

preserve = (f) ->
  (c) -> {(f c)..., value: c.value}

forward = (f) -> (c) -> f() c

log = (f) ->
  (c) ->
    console.log "input", c
    d = f c
    console.log "output", d
    d

set = (key, value) ->
  (c) ->
    value ?= c.value
    (c.data ?= {})[key] = value
    c

get = (key, _default) ->
  (c) ->
    value = ((c.data ?= {})[key] ?= _default)
    {c..., value}

push = (key, value, f) ->
  (c) ->
    s = ((c.data ?= {})[key] ?= [])
    s.unshift value
    d = f c
    s.shift()
    d

apply = (f) ->
  (c) -> (f c.value) c

parser = (f) ->
  (s) ->
    m = f
      original: s
      rest: s
      data: {}

    if m.error?
      # TODO compute line-number and position
      # 1. find position
      # 2. count the newlines up until that position
      # 3. count characters until the first newline prior to position
      {expected, got} = m.error
      got = if got == "" then "end of string" else inspect got[..10]
      throw new Error "parse error:
        expected #{expected}, got #{got}"
    else if m.rest.length > 0
      throw new Error "parse error:
        expected end of input, got #{inspect m.rest[..10]}..."
    else
      m.value

export {
  re
  word
  digits
  ws
  text
  eof
  eol
  pattern
  match
  skip
  negate
  all
  sequence
  any
  many
  optional
  lookahead
  pipe
  map
  flatten
  first
  last
  test
  testContext
  list
  between
  trim
  tag
  merge
  cat
  append
  assign
  assignData
  preserve
  forward
  log
  get
  set
  push
  apply
  parser
}
