import assert from "assert"
import {print, test, success} from "amen"
import "source-map-support/register"

import * as p from "../src"

do ->

  print await test "Parse", [

    test "re", [

      test "success", ->
        parse = p.parser p.re /\d+/, "digits"
        assert.equal "1234", parse "1234"

      test "failure", ->
        assert.throws (-> parse "abc"),
          "parse error: expected digit, got 'abc'"

    ]

  ]

  process.exit if success then 0 else 1
