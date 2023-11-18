#### 1) Load dependencies

library(gtsummary) # For creating a baseline characteristics table
library(tidyverse) # For data wrangling and misc.
library(smd) # for calculating the SMDs
library(purrr) # for vectorised functions


#### 2) Create the core functionality, via **core_smd_function()**, for taking the data and outputting the SMD results

core_smd_function <- function(data, is_weighted, location, ref_group, ci, decimals, ci_bracket, ci_sep) {
  # MAKE A TABLE OF EVERY POSSIBLE COMBO OF TWO DIFFERENT GROUPS
  groups <- factor(unique(data$by))
  pairs <- expand.grid(groups, groups) %>%
    arrange(as.integer(.data$Var1), as.integer(.data$Var2)) %>%
    filter(Var1 != Var2) %>%
    filter(!duplicated(
      paste0(pmax(as.character(Var1), as.character(Var2)),
             pmin(as.character(Var1), as.character(Var2)))))
  if (ref_group) { # IF ref_group, KEEP ONLY PAIRS CONTAINING THE REF GROUP
    pairs <- pairs %>% filter(Var1 == first(levels(groups)))
  }

  # CREATE COLUMN NAMES FOR EACH CALCULATED SMD
  create_colname <- function(pair) {
    filtered_data <- data %>% filter(by %in% pair) %>% mutate(by = factor(by))
    paste0("SMD: ", levels(filtered_data$by)[1], " vs. ", levels(filtered_data$by)[2])
  }
  comparisons <- apply(pairs, 1, create_colname)
  if (location == "level") { comparisons <- paste0(comparisons, " ") }

  # CREATE SUBSETS OF DATA
  subsetting <- function(pair, data) {
    as.data.frame(data) %>%
      filter(by %in% pair) %>%
      mutate(by = factor(by)) %>%
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
  tibble(comp = comparisons, smd = smd_estimates) %>%
    spread(comp, smd) %>%
    relocate(any_of(comparisons))
}


#### 3) Create a function *clean_smd_data()* to prepare the input data for use by the *core_smd_function()*

clean_smd_data <- function(data, variable, by, tbl) {
  tbl_type <- first(class(tbl))
  if (tbl_type != "tbl_svysummary" & tbl_type != "tbl_summary") {
    stop("Inappropriate input to smd function")
  }
  is_weighted <- tbl_type == "tbl_svysummary"

  if (is_weighted) {
    data <- data$variables %>% mutate(weight_var = 1 / data$allprob[[1]])
  } else {
    data <- data %>% mutate(weight_var = 1)
  }

  data <- dplyr::select(data, all_of(c(variable, by, "weight_var"))) %>%
    rlang::set_names(c("variable", "by", "weight_var")) %>%
    dplyr::filter(complete.cases(.))
  if (is.character(data$variable)) {
    data <- data %>% mutate(variable = factor(variable))
  }
  if (is.factor(data$variable)) {
    levels <- levels(data$variable)
  } else {
    levels <- NULL
  }
  return(list(data, levels, is_weighted))
}


#### 4) Create the **add_SMD()** function to be called by users.

# 1) The **location** argument (*"label"*, *"level"*, or *"both"*):
# - Specifying **"label"**, you get **one** SMD per variable. For categorical variables, a Mahalanobis distance is calculated between groups.
# - Specifying **"level"**, you get an SMD *for each level* of all categorical variables. This option thus does not produce SMDs for continuous/numeric variables.
# - Specifying **"both"**, you combine the output of the *level* and the *label* options.
#
# 2) The **ref_group** argument (*TRUE* or *FALSE*):
# - **FALSE**: There is no reference group, and SMDs will be calculated between every possible pair of groups (i.e., groups being defined by the "by" argument in *tbl_summary()* or *tbl_svysummary()*).
# - **TRUE**: The first group (the first level of the variable given in the "by" argument - which is also the leftmost group in the table) will be set as a reference group.
#
# 3) The **ci** argument (*logical*) specifies whether to print confidence intervals for the SMDs.
#
# 4) The **decimals** argument (*integer*) specifies the number of significant digits to print for SMDs (and CIs).
#
# 5) The **ci_bracket** argument can be used to change the bracket type around the confidence intervals.
#
# 6) The **ci_sep** argument changes the separator between the lower and upper limits of confidence intervals.

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
        data <- data %>% mutate(variable = variable == level)
        core_smd_function(data, is_weighted,
                          location = location, ref_group = ref_group,
                          ci = ci, decimals = decimals,
                          ci_bracket = ci_bracket, ci_sep = ci_sep)
      }
      output <- map_dfr(levels, .f = ~ execute_by_level(data, .x, is_weighted))
    }
    return(output)
  }

  if (location == "both") {
    location <- "label"
    tbl <- tbl %>% add_stat(fns = everything() ~ fun, location = ~ "label")
    location <- "level"
    tbl <- tbl %>% add_stat(fns = everything() ~ fun, location = ~ "level")

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
        modify_column_merge(pattern = merge_pattern) %>%
        modify_header(column_names[indices][1] ~ duplicates[i])

    }

  } else {
    tbl <- tbl %>% add_stat(fns = everything() ~ fun, location = ~ location)
  }
  return(tbl)

}


