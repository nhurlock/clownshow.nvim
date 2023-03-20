((member_expression)  @test_each      (#match? @test_each       "^(it.each|test.each|it.concurrent.each|test.concurrent.each|it.failing.each|test.failing.each)$"))
((member_expression)  @test_each_only (#match? @test_each_only  "^(it.only.each|test.only.each|fit.each|it.concurrent.only.each|test.concurrent.only.each)$"))
((member_expression)  @test_each_skip (#match? @test_each_skip  "^(xit.each|xtest.each|it.skip.each|test.skip.each|it.concurrent.skip.each|test.concurrent.skip.each)$"))
