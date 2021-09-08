library(jsonlite)
library(dplyr)
library(readxl)
library(ieugwasr)
library(glue)
ao <- gwasinfo()

datadir <- read_json("config.json")$datadir
dat <- read_xlsx("biomarker_annotations_updated.xlsx")

table(duplicated(dat$`Name in TSV`))
fn <- list.files(file.path(datadir, "ready"), "*.gz")
fn2 <- gsub("_int.imputed.txt.gz", "", fn)
table(fn2 %in% dat$`Name in TSV`)

dat$filename <- paste0(dat$`Name in TSV`, "_int.imputed.txt.gz")
all(file.exists(file.path(datadir, "ready", dat$filename)))

table(dat$`Name in TSV` %in% ao$trait)
table(dat$`Biomarker name` %in% ao$trait)

cmd <- glue("grep 'Number of individuals used in analysis' {datadir}/ready/*log | sed 's@:Number of individuals used in analysis: Nused =@@g' > temp.txt")
system(cmd)
nid <- readr::read_table2("temp.txt", col_names=c("filename", "nid")) %>%
	mutate(filename=basename(filename) %>% gsub("log", "imputed.txt.gz", .)) %>%
	filter(!duplicated(filename))
table(nid$filename %in% dat$filename)
dat <- inner_join(dat, nid, by="filename")

a <- tibble(
	id = paste0("met-d-", dat$`Name in TSV`),
	sample_size = dat$nid,
	sex =  "Males and females",
	category = "Continuous",
	subcategory = "NA",
	unit = "SD",
	group_name = "public",
	build = "HG19/GRCh37",
	author = "Borges CM",
	year = 2020,
	population = "European",
	trait = dat$`Biomarker name`,
	pmid = NA,
	ontology = NA,
	filename = dat$filename,
	nsnp = 12321875,
	delimiter = "tab",
	header = TRUE,
	mr = 1,
	snp_col = 0,
	chr_col = 1,
	pos_col = 2,
	ea_col = 4,
	oa_col = 5,
	eaf_col = 6,
	beta_col = 10,
	se_col = 11,
	pval_col = 15
)

write.csv(a, file="input.csv")
write.csv(a, file=file.path(datadir, "ready", "input.csv"))
