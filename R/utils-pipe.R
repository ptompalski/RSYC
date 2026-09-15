#' Pass a Result to the Next Step
#'
#' `%>%` passes the result on its left to the function on its right. See
#' \code{magrittr::\link[magrittr:pipe]{\%>\%}} for more examples.
#'
#' @name %>%
#' @rdname pipe
#' @keywords internal
#' @export
#' @importFrom magrittr %>%
#' @usage lhs \%>\% rhs
#' @param lhs The result to pass forward.
#' @param rhs The next function to run.
#' @return The result from the function on the right.
NULL
