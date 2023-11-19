#setwd("/Users/au341374/GitHub/Z.gtsummary.addons")

rmarkdown::render('ignore/README.Rmd',
                  output_file = 'README.md',
                  output_format = "github_document",
                  output_dir = "../Z.gtsummary.addons",
                  knit_root_dir = "../",
                  quiet = T)
file.remove("README.html")


tx  <- readLines("README.md")
tx <- paste(tx, collapse="\n")
tx  <- gsub(pattern = "<style>(\r\n|\r|\n|.)*?<[/]style>", replacement = "", x = tx)
writeLines(tx, con="README.md")
