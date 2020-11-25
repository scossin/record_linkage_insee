normalize_X <- function(dataset, meansSd){
  col2remove <- which(colnames(dataset) %in% c("NIP","id","target"))
  if (length(col2remove) > 0){
    X <- as.matrix(dataset[,-col2remove]) ## transform to matrix
  } else {
    X <- as.matrix(dataset)
  } 
   
  ## takes logs of freq:  
  for (colname in c("f_freq_nom","f_freq_prenom")){
    col <- which(colnames(dataset) == colname)
    X[,col] <- log(X[,col])
  } 
  
  for (colname in meansSd$colname){
    moyenne <- meansSd$mean[meansSd$colname == colname]
    ecartType <- meansSd$sd[meansSd$colname == colname] 
    col <- which(colnames(X) == colname)
    X[,col] <- (X[,col] - moyenne) / ecartType
  } 

  rownames(X) <- NULL
  dimnames(X) <- NULL
  ## replace NA value by -1
  bool <- is.na(X)
  X[bool] <- -1 
  return(X)
} 
normalize_set <- function(dataset,meansSd){
  Y <- matrix(as.numeric(as.character(dataset$target)))
  rownames(Y) <- NULL
  dimnames(Y) <- NULL
  Y <- as.numeric(Y)
  X <- normalize_X(dataset,meansSd)
  return(list(
    X = X,
    Y = Y
  ))
} 

#' Compute mean and standard deviation
getMeansSd <- function(training_set,colname){
  col <- which(colnames(training_set) == colname)
  moyenne <- mean(training_set[,col])
  ecartType <- sd(training_set[,col])
  return(data.frame(colname=colname,
                    mean=moyenne,
                    sd=ecartType))
} 