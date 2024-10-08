#' add_SMD_v2
#'
#' @seealso See \code{\link{add_SMD}}
#' @description This is an internal Z.gtsummary.addons function
#' @name add_SMD_v2
#' @rdname add_SMD_v2
#' @author Zheer Kejlberg Al-Mashhadi
#' @keywords internal
#' @usage NULL
#' @export

#### add_SMD(): Create the main function to be called when {gtsummary} version >= v2.0.0

add_SMD_v2 <- function(tbl, location, ref_group, ci, decimals, ci_bracket, ci_sep) {

  tbl <<- tbl
  for (variable in tbl$meta_data$variable) { # first, make variables factors if their type is set to categorical
    if (tbl$meta_data$summary_type[which(tbl$meta_data$variable == variable)] == "categorical") {
      tbl$inputs$data[[variable]] <- factor(tbl$inputs$data[[variable]])
    }
  }

  fun <- function(data, variable, by, tbl, ...) {
    clean_data <<- clean_smd_data(data, variable, by, tbl)
    data <- clean_data[[1]]
    levels <- clean_data[[2]]
    is_weighted <- clean_data[[3]]
    summary_type <- tbl$meta_data$summary_type[which(tbl$meta_data$variable == variable)]


    if (location == "label" | (location == "level" & summary_type == "continuous2")) {
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
    print(output)
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
