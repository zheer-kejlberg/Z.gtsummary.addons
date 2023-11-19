#' round_5_gtsummary
#'
#' @name round_5_gtsummary
#' @rdname round_5_gtsummary
#' @author Zheer Kejlberg Al-Mashhadi
#' @description This function takes a tbl_summary or tbl_svysummary object as input and rounds all counts to nearest 5. If counts are between 0-4, the output will be "<5". Similarly, if counts are between n and n-4, the output will be ">{n-5}".
#' @export
#' @usage round_5_gtsummary(table)
#' @param table Must be a gtsummary object of type 'tbl_summary' or 'tbl_svysummary'.
#' @return Returns a tbl_summary or tbl_svysummary object (same as the input to the "table" argument).
#' @examples
#'   \dontrun{library(gtsummary)
#'   trial %>% tbl_summary(by = "trt") %>% round_5_gtsummary()}

#### round_5_gtsummary(): Create a function to round counts to nearest 5

round_5_gtsummary <- function(table) {

  round_5 <- function(x) { round(x/5)*5 }

  round_5_get_summary <- function(x, N, decimals = 1) {
    x <- stringr::str_remove(x, " \\([<]*[0-9]*[,]*[0-9]*[.]*[0-9]*%\\)$")
    x <- as.numeric(stringr::str_remove(x, ","))

    if (x > N-5) {
      N <- round_5(N)
      return(paste0(">", N-5, "(>", round((N-5)/N*100, decimals), "%)"))
    } else if (x >= 5) {
      return(paste0(round_5(x), " (", round(round_5(x)/round_5(N)*100,decimals),"%)"))
    } else {
      return(paste0("<", 5," (<", round(5/round_5(N)*100,decimals),"%)"))
    }
  }

  body <- table$table_body
  stats_column_indices <- which(grepl("^stat_", colnames(body)))

  Ns <- table$table_styling$header$modify_stat_n[c(stats_column_indices)]
  table$table_styling$header$label[c(stats_column_indices)] <- paste0("**", table$table_styling$header$modify_stat_level[c(stats_column_indices)], "**", ", N = ", round_5(Ns))

  for (column_no in stats_column_indices) {
    column <- dplyr::pull(body, column_no)
    cat_indices <- (body$var_type == "categorical" | body$var_type == "dichotomous" | body$label == "Unknown") & !is.na(body$stat_1)
    N <- table$table_styling$header$modify_stat_n[column_no]
    column[cat_indices] <- sapply(column[cat_indices], round_5_get_summary, N = N)
    table$table_body[column_no] <- column
  }
  return(table)
}
