(expression_statement
  (call_expression
    function: ([
      OUTER_TEST
      ((identifier)        @idescribe          (#eq? @idescribe          "describe"))
      ((identifier)        @idescribe_skip     (#eq? @idescribe_skip     "xdescribe"))
      ((member_expression) @idescribe_skip_alt (#eq? @idescribe_skip_alt "describe.skip"))
      ((identifier)        @idescribe_only     (#eq? @idescribe_only     "fdescribe"))
      ((member_expression) @idescribe_only_alt (#eq? @idescribe_only_alt "describe.only"))
      (call_expression
        function: ([
          INNER_TEST
          ((member_expression) @idescribe_each       (#eq? @idescribe_each       "describe.each"))
          ((member_expression) @idescribe_each_only  (#eq? @idescribe_each_only  "describe.only.each"))
          ((member_expression) @idescribe_each_skip  (#eq? @idescribe_each_skip  "describe.skip.each"))
        ])
      )
    ])
    arguments: (_) @inner_args
  ))
