## premier téléchargement réalisé via:
# http://data.cquest.org/insee_deces/
# (fichier du site dans le dossier)

html <- readLines("./data_cquest_org.html")
regex <- "deces-[0-9]+(-m[0-9]+)?.txt"
library(stringr)
files <- stringr::str_extract_all(html, regex)
files <- unlist(files)
files <- unique(files)
files
## keep only >= 2005
files <- files[36:length(files)] 
files
base_url <- "http://data.cquest.org/insee_deces/"

file <- files[1] 
for (file in files){
  url <- paste0(base_url,file)
  filename <- paste0("./data/",file)
  if (base::file.exists(filename)){
    cat(filename, "already exists\n")
    next
  } 
  utils::download.file(url=url,destfile = filename)
} 




