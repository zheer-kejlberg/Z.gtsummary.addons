#' add_SMD
#'
#' @seealso See \code{\link[gtsummary]{tbl_summary}} and \code{\link[gtsummary]{tbl_svysummary}}
#'
#' @name add_SMD
#' @rdname add_SMD
#' @author Zheer Kejlberg Al-Mashhadi
#' @description This function takes a tbl_summary or tbl_svysummary object as input and adds columns with standardised mean differences (SMDs) between the "by"-groups in the table. There is the option to compute SMDs between every possible pair of groups or, alternatively, between one reference group and all other groups.
#' @export
#' @usage add_SMD(tbl, location, ref_group, ci, decimals, ci_bracket, ci_sep)
#' @param tbl Must be a gtsummary object of type 'tbl_summary' or 'tbl_svysummary'.
#' @param location Can be set to "label" (one SMD is computed for each variable; for categorical variables, a Mahalanobis distance is computed [1]), "level" (an SMD is computed for every level of categorical variables), or "both" (a combination of both "label" and "level"). Default is "label".
#' @param ref_group Binary. If TRUE, group 1 is set as a reference group, and SMDs are computed between it and all other groups. If FALSE, every pairwise combination of groups is computed. Default is FALSE.
#' @param ci Binary. If TRUE, confidence intervals are added to the SMDs.
#' @param decimals Integer. Sepcified the number of decimals to round to for SMDs (and confidence intervals).
#' @param ci_bracket Character. Default is set to "{}". Any string can be specified; the first character will be used as the opening bracket for the confidence interval, and the second character as the closing bracket.
#' @param ci_sep Character. Default is ", ". Specified the separator characters to use between the lower and the upper confidence bounds.
#' @return Returns a tbl_summary or tbl_svysummary object (same as the input to the "tbl" argument) with added SMDs.
#' @examples
#'   \dontrun{library(gtsummary)
#'   trial %>% tbl_summary(by = "trt") %>% add_SMD()}
#' @references [1]: Yang & Dalton (2012): A unified approach to measuring the effect size between two groups using SAS® (https://support.sas.com/resources/papers/proceedings12/335-2012.pdf)

#### add_SMD(): Determine {gtsummary} version and call the corresponding add_SMD() version

add_SMD <- function(tbl, location = "label", ref_group = FALSE, ci = FALSE, decimals = 2, ci_bracket = "()", ci_sep=", ") {
  gtsummary_version <- as.integer(substring(packageVersion("gtsummary"), 1, 1))
  if (gtsummary_version >= 2) {
    add_SMD_v2(tbl, location, ref_group, ci, decimals, ci_bracket, ci_sep)
  } else {
    add_SMD_v1(tbl, location, ref_group, ci, decimals, ci_bracket, ci_sep)
  }
}
