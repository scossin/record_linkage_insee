countNames <- read.table("./countName.tsv",sep="\t",
                         header=T)
colnames(countNames) <- c("name","count")
countNames <- subset(countNames, !is.na(countNames$name))

countPrenom1 <- read.table("./countPrenom1.tsv",sep="\t",
                           header=T)
colnames(countPrenom1) <- c("prenom1","count")
countPrenom1 <- subset(countPrenom1, !is.na(countPrenom1$prenom1))
