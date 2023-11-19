#' add_SMD
#'
#' @seealso See \code{\link[Z.gtsummary.addons::tbl_summary]{tbl_summary}} and \code{\link[Z.gtsummary.addons::tbl_svysummary]{tbl_svysummary}}
#'
#' @name add_SMD
#' @rdname add_SMD
#' @description This function takes a tbl_summary or tbl_svysummary object as input and adds columns with standardised mean differences (SMDs) between the "by"-groups in the table. There is the option to compute SMDs between every possible pair of groups or, alternatively, between one reference group and all other groups.
#' @export
#' @usage add_SMD(tbl, location, ref_group, ci, decimals, ci_bracket, ci_sep)
#' @param location Can be set to "label" (one SMD is computed for each variable; for categorical variables, a Mahalanobis distance is computed [1]), "level" (an SMD is computed for every level of categorical variables), or "both" (a combination of both "label" and "level"). Default is "label".
#' @param ref_group Binary. If TRUE, group 1 is set as a reference group, and SMDs are computed between it and all other groups. If FALSE, every pairwise combination of groups is computed. Default is FALSE.
#' @param ci Binary. If TRUE, confidence intervals are added to the SMDs.
#' @param decimals Integer. Sepcified the number of decimals to round to for SMDs (and confidence intervals).
#' @param ci_bracket Character. Default is set to "{}". Any string can be specified; the first character will be used as the opening bracket for the confidence interval, and the second character as the closing bracket.
#' @param ci_sep Character. Default is ", ". Specified the separator characters to use between the lower and the upper confidence bounds.
#' @return Returns a tbl_summary or tbl_svysummary object (same as the input to the "tbl" argument) with added SMDs.
#' @references [1]: Yang & Dalton (2012): A unified approach to measuring the effect size between two groups using SAS® (https://support.sas.com/resources/papers/proceedings12/335-2012.pdf)

#### add_SMD(): Create the main function to be called by users.

add_SMD <- function(tbl, location = "label", ref_group = FALSE, ci = FALSE, decimals = 2, ci_bracket = "()", ci_sep=", ") {
  fun <- function(data, variable, by, tbl, ...) {
    clean_data <- clean_smd_data(data, variable, by, tbl)
    data <- clean_data[[1]]
    levels <- clean_data[[2]]
    is_weighted <- clean_data[[3]]

    if (location == "label") {
      output <- core_smd_function(data, is_weighted,
                                  location = location, ref_group = ref_group,
                                  ci = ci, decimals = decimals,
                                  ci_bracket = ci_bracket, ci_sep = ci_sep)
    } else { # location == "level"
      execute_by_level <- function(data, level, is_weighted) {
        data <- data %>% dplyr::mutate(variable = variable == level)
        core_smd_function(data, is_weighted,
                          location = location, ref_group = ref_group,
                          ci = ci, decimals = decimals,
                          ci_bracket = ci_bracket, ci_sep = ci_sep)
      }
      output <- purrr::map_dfr(levels, .f = ~ execute_by_level(data, .x, is_weighted))
    }
    return(output)
  }

  if (location == "both") {
    location <- "label"
    tbl <- tbl %>% gtsummary::add_stat(fns = everything() ~ fun, location = ~ "label")
    location <- "level"
    tbl <- tbl %>% gtsummary::add_stat(fns = everything() ~ fun, location = ~ "level")

    duplicates <- stringr::str_subset(tbl$table_styling$header$column, "^SMD(\r\n|\r|\n|.)* $")
    duplicates <- stringr::str_remove(duplicates, " $")

    for (i in 1:length(duplicates)) {
      # Temporarily change column names for use by gtsummary
      column_names <- colnames(tbl$table_body)
      indices <- which(column_names == duplicates[i] | column_names == paste0(duplicates[i], " "))
      column_names[indices] <- stringr::str_replace_all(column_names[indices], "[: .]", "_")
      colnames(tbl$table_body) <- column_names

      # Adjust the digits of the SMDs and turn into character (while hiding NAs)
      format_smd <- function(column) {
        column[is.na(column)] <- ""
        return(column)
      }
      tbl$table_body[[column_names[indices][1]]] <- format_smd(tbl$table_body[[column_names[indices][1]]])
      tbl$table_body[[column_names[indices][2]]] <- format_smd(tbl$table_body[[column_names[indices][2]]])

      # Finally merge and reinstate the original column title
      merge_pattern <- paste0("{",column_names[indices][1],"}{",column_names[indices][2],"}")
      tbl <- tbl %>%
        gtsummary::modify_column_merge(pattern = merge_pattern) %>%
        gtsummary::modify_header(column_names[indices][1] ~ duplicates[i])
    }
  } else {
    tbl <- tbl %>% gtsummary::add_stat(fns = everything() ~ fun, location = ~ location)
  }
  return(tbl)
}
