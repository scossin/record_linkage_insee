departement <- read.table("departements-francais.csv",
                          sep="\t",
                          quote="",
                          header=T,
                          fileEncoding = "UTF-8")
colnames(departement) <- c("code","nom_dep","region","chef_lieu","superficie",
                           "pouplation","densite")
departement <- subset(departement, select=c("code","region"))