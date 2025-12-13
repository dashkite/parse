import * as Fn from "@dashkite/joy/function"
import * as Type from "@dashkite/joy/type"

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

sequence = join = Fn.curry (delimiter, fx) ->
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

many = ( x, min = 0, max = undefined ) ->
  f = pattern x
  
  (c) ->
    d = c
    value = []
    while d.rest.length > 0
      if !(m = f d).error?
        value.push m.value if m.value?
        d = {d..., m..., value}
        break if max? && value.length == max
      else
        break
    if value.length >= min
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

second = map (ax) -> ax[1]

third = map (ax) -> ax[2]

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

list = Fn.curry (d, x) ->
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
      if rest?
        [ first, rest... ]
      else
        [ first ]
  ]

between = Fn.curry (d, f) ->
  if Type.isArray d
    [ d1, d2 ] = d
  else
    d1 = d2 = d

  pipe [
    all [
      skip d1
      f
      skip d2
    ]
    map ([value]) -> value
  ]

strip = (x) -> skip optional x

tag = (key) -> map (value) -> [key]: value

merge = (c) ->
  r = {}
  for _tag in c.value
    for key, value of _tag
      if r[key]?
        if Array.isArray r[key]
          r[key].push value
        else
          r[key] = [ r[key], value ]
      else
        r[key] = value
  c.value = r
  c

cat = map (ax) -> ax.join ""

trim = map (text) -> text.trim()

forward = (f) -> (c) -> f() c

log = (label) ->
  (c) ->
    if label?
      console.log label, JSON.stringify c, null, 2
    else
      console.log JSON.stringify c, null, 2
    c


assign = (object) ->
  Fn.tee (c) -> Object.assign c.data, object
 
set = (key, value) ->
  (c) ->
    value ?= c.value
    (c.data ?= {})[key] = value
    c

get = (key, _default) ->
  (c) ->
    value = ((c.data ?= {})[key] ?= _default)
    {c..., value}

verify = (expected, f) -> (c) -> 
  if f c.value then c else { c..., error: { expected, got: c.rest } }

parser = (f) ->
  (s) ->
    m = f
      original: s
      rest: s
      data: {}

    if m.error?
      { expected, got } = m.error
      got = if got.length == 0 then "end of input" else inspect got[..5]
      throw new Error "parse error:
        expected #{expected}, got #{got}"
    else if m.rest.length > 0
      throw new Error "parse error:
        expected end of input, got #{ inspect m.rest[..5]}..."
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
  strip
  negate
  all
  sequence
  join
  any
  many
  optional
  lookahead
  pipe
  map
  flatten
  first
  second
  third
  last
  test
  list
  between
  trim
  tag
  merge
  cat
  forward
  log
  assign
  verify
  parser
}
