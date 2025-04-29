CRdeclining2 <- function(age, b1, b2, b3, b4) { #four-parameter declining CR 
  b1 * exp(-b4 * age) * (1 - exp(-b2 * age))^b3
  
}



assert_is_numeric = function(x)
{
  x. <- lazyeval::expr_text(x)
  if (!is.numeric(x))
    stop(glue::glue("{x.} must be numeric (not {class(x)})."), call. = FALSE)
}
assert_is_character <- function(x) {
  x. <- lazyeval::expr_text(x)
  if (!is.character(x))
    stop(glue::glue("{x.} must be character (not a {class(x)})."), call. = FALSE)
}
assert_all_are_positive = function(x)
{
  x. <- lazyeval::expr_text(x)
  if (!all(x > 0))
    stop(glue::glue("All values of {x.} must be positive."), call. = FALSE)
}
