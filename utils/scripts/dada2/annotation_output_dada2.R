suppressMessages(library("dplyr"))

## Importing data
taxa_UNITE<-read.table(snakemake@input[["file"]],header=TRUE, row.names = 1, sep = "\t")
taxa_UNITE<-cbind(taxa_UNITE,rownames(taxa_UNITE))
colnames(taxa_UNITE)[8]<-"asv_seq"

seqtab<-readRDS(snakemake@input[["seqs"]])
seqtab2<-t(seqtab)


#Calculating total abundance of each ASV
seqtab3<-cbind(rowSums(seqtab2),seqtab2);colnames(seqtab3)[1]<-"total"

#adding ASVs as a column to seqtab
seqtab4<-data.frame(cbind(rownames(seqtab3),seqtab3))
colnames(seqtab4)[1]<-"asv_seq"


##Genering ASV_number,sequences and length columns
df<-data.frame(cbind(paste0("ASV_",seq_along(1:nrow(taxa_UNITE))),rownames(taxa_UNITE),length<-nchar(rownames(taxa_UNITE))))
colnames(df)<-c("asv_id", "asv_seq","asv_len")

#joining all taxonoy files ands seq table by ASV seqs

df1<-left_join(df,taxa_UNITE,by="asv_seq")
df2<-left_join(df1,seqtab4,by="asv_seq")


colnames(df2)[1:10]<-c("asv_id", "asv_seq", "asv_len",	
                         "kingdom_UNITE", "phylum_UNITE",	"class_UNITE",	"order_UNITE",	
                         "family_UNITE",	"genus_UNITE",	"species_UNITE")
    

colnames(df2) <- gsub("^X", "", colnames(df2))
write.csv(df2,snakemake@output[["table"]],row.names = F)
