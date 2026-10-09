# Pass a Result to the Next Step

`%>%` passes the result on its left to the function on its right. See
`magrittr::%>%` for more examples.

## Usage

``` r
lhs %>% rhs
```

## Arguments

- lhs:

  The result to pass forward.

- rhs:

  The next function to run.

## Value

The result from the function on the right.
