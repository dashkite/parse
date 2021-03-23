import assert from "assert"
import {print, test, success} from "amen"
import "source-map-support/register"

import * as p from "../src"

do ->

  print await test "Parse", [

    test "re", do ->

      parse = p.parser p.re /\d+/, "digits"

      [

        test "success", ->
          assert.equal "1234", parse "1234"

        test "failure", ->
          parse = p.parser p.re /\d+/, "digits"
          assert.throws (-> parse "abc"),
            message: 'parse error: expected digits, got "abc"'

      ]

    test "text", do ->

      parse = p.parser p.text "hello"

      [

        test "success", ->
          assert.equal "hello", parse "hello"

        test "failure", ->
          assert.throws (-> parse "goodbye"),
            message: 'parse error: expected "hello", got "goodbye"'

        test "incomplete", ->
          assert.throws (-> parse "hello!"),
            message: 'parse error: expected end of input, got "!"'

      ]

    test "pipe, match", do ->

      parse = p.parser p.pipe [ p.match p.text "hello" ]

      [
        test "success", ->
          assert.equal "hello", parse "hello"

        test "failure", ->
          assert.throws ( -> parse "goodbye"),
            message: 'parse error: expected "hello", got "goodbye"'

      ]

    test "all, skip, ws, text", do ->

      parse = p.parser p.all [
        p.skip p.ws
        p.text "hello"
      ]

      [

        test "success", ->
          assert.deepEqual [ "hello" ], parse "  hello"

        test "failure", ->
          assert.throws (-> parse "hello"),
            message: 'parse error: expected whitespace, got "hello"'

      ]

    test "any, text", do ->

      parse = p.parser p.any [
        p.text "hello"
        p.text "goodbye"
      ]

      [
        test "success", ->
          assert.equal "hello", parse "hello"
          assert.equal "goodbye", parse "goodbye"

        test "failure", ->
          assert.throws (-> parse "ciao"),
            message: 'parse error: expected "goodbye", got "ciao"'
      ]

    test "many, text", do ->

      parse = p.parser p.many p.text "-"

      [

        test "success", ->
          assert.equal "---", (parse "---").join ""

        test "failure", ->
          assert.throws (-> parse "--+-"),
            message: 'parse error: expected end of input, got "+-"'

      ]

    test "optional, skip, ws", do ->

      parse = p.parser p.all [
        p.skip p.optional p.ws
        p.text "hello"
      ]

      [

        test "success", ->
          assert.deepEqual [ "hello" ], parse "hello"
          assert.deepEqual [ "hello" ], parse "  hello"

        test "failure", ->
          assert.throws (-> parse "  goodbye"),
            message: 'parse error: expected "hello", got "goodbye"'


      ]

    test "between", do ->

      parse = p.parser p.between '"', p.text "hello"

      [

        test "success", ->
          assert.equal "hello", parse '"hello"'

        test "failure", ->
          assert.throws (-> parse '"goodbye"'),
            message: 'parse error: expected "hello", got "goodbye\\""'

          assert.throws (-> parse 'hello'),
            message: 'parse error: expected "\\"", got "hello"'


      ]

    test "list", do ->

      parse = p.parser p.list ",", /^\d+/

      [

        test "success", ->
          assert.deepEqual ["1", "2", "3", "4"], parse "1,2,3,4"

        test "failure", ->
          assert.throws (-> parse "1,2,3,"),
            message: "parse error: expected /^\\d+/, got end of string"

      ]

    test "test", do ->

      parse = p.parser p.pipe [
        p.match p.re /^\d+/, "digit"
        p.map (value) -> Number.parseInt value, 10
        p.test "an odd number", (value) -> value % 2 == 0
      ]

      [
        test "success", ->
          assert.equal 4, parse "4"

        test "failure", ->
          assert.throws (-> parse "5"),
            message: 'parse error: expected an odd number, got "5"'
      ]

    test "scenario: nested list, significant whitespace", do ->

      bol = p.skip p.pipe [
        p.get "indent", []
        p.apply p.all
      ]

      block = (f, g) -> p.push "indent", f, g

      item = p.first p.all [
        bol
        p.any [
          p.first p.all [
            p.skip "- "
            p.word
            p.skip p.eol
          ]
          block (p.text "  "), p.forward -> list
        ]
      ]

      list = p.pipe [
        p.lookahead /^\s*\-/, "list"
        p.many item
      ]

      parse = p.parser list

      [

        test "success", ->

          assert.deepEqual [
            "fruits"
            [ "apples", "bananas" ]
            "vegetables"
            [ "potatos" ]
          ], parse """
              - fruits
                - apples
                - bananas
              - vegetables
                - potatos
              """

        test "failure", ->

          assert.throws (->
            parse """
              - fruits
                apples
              """),
            message: 'parse error: expected end of input, got "  apples"'
      ]


    test "scenario: expression grammar", do ->

      parse = p.parser p.pipe [
        p.all [
          p.re /^\d+/, "digit"
          p.trim p.ws
          p.re /^(\+|-)/, "operator"
          p.trim p.ws
          p.re /^\d+/, "digit"
        ]
        p.map ([x, op, y]) ->
          x = Number.parseInt x, 10
          y = Number.parseInt y, 10
          switch op
            when "+" then x + y
            when "-" then x - y
      ]

      [
          test "success", ->
            assert.equal 8, parse "5 + 3"
            assert.equal 2, parse "5 - 3"

          test "failure", ->
            assert.throws (-> parse "7 + a"),
              message: 'parse error: expected digit, got "a"'
      ]

  ]

  process.exit if success then 0 else 1
