#' core_smd_function
#'
#' @seealso See \code{\link{add_SMD}}
#' @description This is an internal Z.gtsummary.addons function
#' @name core_smd_function
#' @rdname core_smd_function
#' @author Zheer Kejlberg Al-Mashhadi
#' @keywords internal
#' @usage NULL
#' @export

#### add_SMD(): Create the core functionality for taking the data and outputting the SMD results

core_smd_function <- function(data, is_weighted, location, ref_group, ci, decimals, ci_bracket, ci_sep) {
  # MAKE A TABLE OF EVERY POSSIBLE COMBO OF TWO DIFFERENT GROUPS
  groups <- factor(unique(data$by))
  pairs <- expand.grid(groups, groups) %>%
    dplyr::arrange(as.integer(.data$Var1), as.integer(.data$Var2)) %>%
    dplyr::filter(Var1 != Var2) %>%
    dplyr::filter(!duplicated(
      paste0(pmax(as.character(Var1), as.character(Var2)),
             pmin(as.character(Var1), as.character(Var2)))))
  if (ref_group) { # IF ref_group, KEEP ONLY PAIRS CONTAINING THE REF GROUP
    pairs <- pairs %>% dplyr::filter(Var1 == dplyr::first(levels(groups)))
  }

  # CREATE COLUMN NAMES FOR EACH CALCULATED SMD
  create_colname <- function(pair) {
    filtered_data <- data %>% dplyr::filter(by %in% pair) %>% dplyr::mutate(by = factor(by))
    paste0("SMD: ", levels(filtered_data$by)[1], " vs. ", levels(filtered_data$by)[2])
  }
  comparisons <- apply(pairs, 1, create_colname)
  if (location == "level") { comparisons <- paste0(comparisons, " ") }

  # CREATE SUBSETS OF DATA
  subsetting <- function(pair, data) {
    as.data.frame(data) %>%
      dplyr::filter(by %in% pair) %>%
      dplyr::mutate(by = factor(by)) %>%
      droplevels()
  }
  data_subsets <- apply(X = pairs, MARGIN = 1, FUN = subsetting, data = data)

  # CALCULATE SMD BETWEEN GROUPS WITHIN EACH DATA SUBSET
  calc_SMD <- function(data_subset, is_weighted, ci, decimals) {
    res <- smd::smd(data_subset$variable, data_subset$by, std.error = T)
    if (is_weighted) {
      res <- smd::smd(data_subset$variable, data_subset$by, data_subset$weight_var, std.error = T)
    }
    res_smd <- res[[2]] %>% round(decimals) %>% format(nsmall = decimals)
    ci_lower <- (res[[2]] - 1.96 * res[[3]]) %>% round(decimals) %>% format(nsmall = decimals)
    ci_upper <- (res[[2]] + 1.96 * res[[3]]) %>% round(decimals) %>% format(nsmall = decimals)

    if (ci == TRUE) {
      output <- paste(res_smd, " ",
                      substr(ci_bracket,1,1), ci_lower, ci_sep, ci_upper, substr(ci_bracket,2,2),
                      sep = "")
      return(output)
    } else {
      return(res_smd)
    }
  }
  calc_SMD <- purrr::possibly(.f = calc_SMD, otherwise = NA_character_)

  smd_estimates <- purrr::map_chr(data_subsets, ~ calc_SMD(., is_weighted, ci, decimals))

  # OUTPUT THE RESULTS
  tibble::tibble(comp = comparisons, smd = smd_estimates) %>%
    tidyr::spread(comp, smd) %>%
    dplyr::relocate(tidyselect::any_of(comparisons))
}
