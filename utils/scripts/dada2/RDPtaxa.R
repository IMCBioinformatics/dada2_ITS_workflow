
suppressMessages(library(dada2))
suppressMessages(library(Biostrings))


seqtab= readRDS(snakemake@input[['seqtab']]) # seqtab

set.seed(snakemake@config[['seed']]) # Initialize random number generator for reproducibility

taxtab <- assignTaxonomy(seqtab, refFasta = snakemake@input[['ref']],tryRC=TRUE,multithread=snakemake@threads,outputBootstraps = T)


saveRDS(taxtab$boot,file=snakemake@output[['rds_bootstrap']])

write.table(taxtab$tax,snakemake@output[['taxonomy']],sep='\t')
