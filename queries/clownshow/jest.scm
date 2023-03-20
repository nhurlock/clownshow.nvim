(expression_statement
  (call_expression
    function: ([
      ((identifier)        @describe          (#eq? @describe          "describe"))
      ((identifier)        @describe_skip     (#eq? @describe_skip     "xdescribe"))
      ((member_expression) @describe_skip_alt (#eq? @describe_skip_alt "describe.skip"))
      ((identifier)        @describe_only     (#eq? @describe_only     "fdescribe"))
      ((member_expression) @describe_only_alt (#eq? @describe_only_alt "describe.only"))
      (call_expression
        function: ([
          ((member_expression) @describe_each       (#eq? @describe_each       "describe.each"))
          ((member_expression) @describe_each_only  (#eq? @describe_each_only  "describe.only.each"))
          ((member_expression) @describe_each_skip  (#eq? @describe_each_skip  "describe.skip.each"))
        ])
      )
    ])
    arguments: (arguments ([
      (arrow_function
        body: (statement_block TEST_EXPRESSION))
      (function
        body: (statement_block TEST_EXPRESSION))
    ])) @args
  ))
(expression_statement
  (call_expression
    function: ([
      OUTER_TEST
      (call_expression
        function: ([
          INNER_TEST
        ])
      )
    ])
    arguments: (_) @inner_args
  ))
