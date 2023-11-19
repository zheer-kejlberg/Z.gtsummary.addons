\name{add_SMD}
\alias{add_SMD}

\title{
add_SMD
}

\description{
%%  ~~ A concise (1-5 lines) description of what the function does. ~~
This function takes a tbl_summary or tbl_svysummary object as input and adds columns with standardised mean differences (SMDs) between the "by"-groups in the table.
There is the option to compute SMDs between every possible pair of groups or, alternatively, between one reference group and all other groups.
}
\usage{
add_SMD(tbl, location, ref_group, ci, decimals, ci_bracket, ci_sep)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{tbl}{
A tbl_summary or tbl_svysummary object
}  \item{location}{
Can be set to "label" (one SMD is computed for each variable; for categorical variables, a Mahalanobis distance is computed [1]), "level" (an SMD is computed for every level of categorical variables), or "both" (a combination of both "label" and "level"). Default is "label".
}  \item{ref_group}{
Binary. If TRUE, group 1 is set as a reference group, and SMDs are computed between it and all other groups. If FALSE, every pairwise combination of groups is computed. Default is FALSE.
}  \item{ci}{
Binary. If TRUE, confidence intervals are added to the SMDs.
}  \item{decimals}{
Integer. Sepcified the number of decimals to round to for SMDs (and confidence intervals).
}  \item{ci_bracket}{
Character. Default is set to "{}". Any string can be specified; the first character will be used as the opening bracket for the confidence interval, and the second character as the closing bracket.
}  \item{ci_sep}{
Character. Default is ", ". Specified the separator characters to use between the lower and the upper confidence bounds.
}
}

\value{
Returns a tbl_summary or tbl_svysummary object (same as the input to the "tbl" argument) with added SMDs.
}
\references{
[1]: Yang & Dalton (2012): A unified approach to measuring the effect size between two groups using SAS® (https://support.sas.com/resources/papers/proceedings12/335-2012.pdf)
}
\author{
Zheer Kejlberg Al-Mashhadi
}


%% ~Make other sections like Warning with \section{Warning }{....} ~

\seealso{
%% ~~objects to See Also as \code{\link{help}}, ~~~
`tbl_summary` and `tbl_svysummary`
}
\examples{

### library(gtsummary)
### trial \%>\% tbl_summary(by = "trt") \%>\% add_SMD()

}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory (show via RShowDoc("KEYWORDS")):
% \keyword{ ~kwd1 }
% \keyword{ ~kwd2 }
% Use only one keyword per line.
% For non-standard keywords, use \concept instead of \keyword:
% \concept{ ~cpt1 }
% \concept{ ~cpt2 }
% Use only one concept per line.
