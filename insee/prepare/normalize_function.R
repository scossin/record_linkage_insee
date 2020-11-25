normalize_txt <- function(x){
  x <- gsub("[[:punct:]]"," ",x) ## remove punctuation  
  x <- gsub("[ ]+"," ",x) # remove multiple space 
  x <- trimws(x) # remove trailing space  
  x <- iconv(x, from="UTF-8", to='ASCII//TRANSLIT') ## remove accents/diacritics symbols
  return(x)
}
