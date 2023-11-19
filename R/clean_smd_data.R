#' clean_smd_data
#'
#' See See \code{\link[Z.gtsummary.addons::add_SMD]{add_SMD}}
#'
#' @name clean_smd_data
#' @rdname clean_smd_data
#' @keywords internal
#' @export


#### add_SMD(): Create a function to prepare the input data for use by the *core_smd_function()*

clean_smd_data <- function(data, variable, by, tbl) {
  tbl_type <- dplyr::first(class(tbl))
  if (tbl_type != "tbl_svysummary" & tbl_type != "tbl_summary") {
    stop("Inappropriate input to smd function")
  }
  is_weighted <- tbl_type == "tbl_svysummary"

  if (is_weighted) {
    data <- data$variables %>% dplyr::mutate(weight_var = 1 / data$allprob[[1]])
  } else {
    data <- data %>% dplyr::mutate(weight_var = 1)
  }

  data <- dplyr::select(data, tidyselect::all_of(c(variable, by, "weight_var"))) %>%
    rlang::set_names(c("variable", "by", "weight_var")) %>%
    dplyr::filter(stats::complete.cases(.))
  if (is.character(data$variable)) {
    data <- data %>% dplyr::mutate(variable = factor(variable))
  }
  if (is.factor(data$variable)) {
    levels <- levels(data$variable)
  } else {
    levels <- NULL
  }
  return(list(data, levels, is_weighted))
}
