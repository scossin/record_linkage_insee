code_commune_postal <- read.table("externalData/code_postal_commune.tsv",
                                  sep="\t",
                                  header=T)
code_commune_postal$code_postal <- as.character(code_commune_postal$code_postal)
