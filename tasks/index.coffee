import * as t from "@dashkite/genie"
import preset from "@dashkite/genie-presets"

preset t

# avoid loading genie-modules unless we're actually publishing
# because genie-modules uses graphene-core which relies on polaris
t.define "publish", ->
  # TODO rewrite as dynamic import when we move to ESM in Node
  { default: modules } = require "@dashkite/genie-modules"
  modules t
  t.run "modules:publish"
