setwd("/Users/au341374/GitHub/Z.gtsummary.addons")
rmarkdown::render('R/README.Rmd',
                  output_file = 'README.md',
                  output_format = "github_document",
                  output_dir = "/Users/au341374/GitHub/Z.gtsummary.addons",
                  knit_root_dir = "/Users/au341374/GitHub/Z.gtsummary.addons",
                  quiet = T)
