# ------------------------------------------------------------------------------
# Downloads WRDS data to local parquet files using a duckdb/postgres workflow
# See LICENSE file for licensing ;-) 
# ------------------------------------------------------------------------------

# Good starting points to learn more about this workflow are
# - The support pages of WRDS (they also contain the data documentation)
# - The wonderful textbook by Ian Gow (https://iangow.github.io/far_book/),
#   in particular App. D and E

suppressWarnings(suppressPackageStartupMessages({
  library(duckdb)
  library(logger)
	library(hms)
}))

# By default the code only downloads missing data. Set the below
# to TRUE if you want to re-download everything.
FORCE_REDOWNLOAD <- FALSE

if (file.exists("config.env")) readRenviron("config.env") else {
  stop(paste(
    "Please copy '_config.env' to 'config.env' and edit it to", 
    "contain your WRDS access data prior to running this code"
  ))
}

link_wrds_to_duckdb <- function(con) {
  rv <- dbExecute(
    con, sprintf(paste(
      "INSTALL postgres;",
      "LOAD postgres;",
      "SET pg_connection_limit=4;",
      "ATTACH '",
      "dbname=wrds host=wrds-pgdata.wharton.upenn.edu port=9737",
      "user=%s password=%s' AS wrds (TYPE postgres, READ_ONLY)"
    ), Sys.getenv("WRDS_USER"), Sys.getenv("WRDS_PWD"))
  )
}

list_wrds_libs_and_tables <- function(con) {
  dbGetQuery(
    con, "SHOW ALL TABLES"
  )
}

download_wrds_table <- function(
  con, lib, table, parquet_file = "", parquet_path = "data/pulled", 
  select_query = "*", where_query = "" 
) {
  time_in <- Sys.time()
  if (parquet_file == "") {
    parquet_file <- paste0(lib, "_", table, ".parquet")
  }
  parquet_fpath <- file.path(parquet_path, parquet_file)
  if (!dir.exists(parquet_path)) {
    dir.create(parquet_path)
  }
  if (file.exists(parquet_fpath) & ! FORCE_REDOWNLOAD) {
    log_info(
      "Parquet file '{parquet_fpath}' exists. ",
      "Skipping download but updating its mtime"
    )
    Sys.setFileTime(parquet_fpath, Sys.time())
    return(invisible())
  }
  log_info(
    "Download WRDS data to parquet file '{parquet_fpath}'"
  )
  if (where_query != "") {
    where_query <- paste("WHERE", where_query)
  }
  rv <- dbExecute(
    con, sprintf(
      "COPY (SELECT %s FROM wrds.%s.%s %s) TO '%s'", 
      select_query, lib, table, where_query, parquet_fpath
    )
  )
  time_spent <- round(Sys.time() - time_in)
  log_info(
    'Created parquet file with {format(rv, big.mark = ",")} rows, ', 
    "time spent: {as_hms(time_spent)})"
  )
}

# --- Connect to WRDS ----------------------------------------------------------

log_info("Start WRDS Download")

db <- dbConnect(duckdb::duckdb(), "data/temp/wrds_local.duckdb")
link_wrds_to_duckdb(db)

log_info("Linked WRDS to local Duck DB instance")


# --- Pull Orbis data from WRDS ----------------------------------

# We only pull German data
ctries <- c("DE")

# Financial data comes in three sizes: large, medium and small
for (ctry in ctries) {
  for (size in c("l", "m", "s")) {
    download_wrds_table(
      db, "bvd", sprintf("ob_ind_g_fins_eur_%s", size), 
      parquet_file = sprintf(
      	"orbis_ind_g_fins_eur_%s_%s.parquet", size, tolower(ctry)
      ),
      where_query = sprintf("ctryiso = '%s'", ctry)
    )
  }
}

# Legal info
for (ctry in ctries) {
	for (size in c("l", "m", "s")) {
		download_wrds_table(
			db, "bvd", sprintf("ob_legal_info_%s", size), 
			parquet_file = sprintf(
				"orbis_legal_info_%s_%s.parquet", size, tolower(ctry)
			),
			where_query = sprintf("ctryiso = '%s'", ctry)
		)
	}
}

# Basic shareholder info
for (ctry in ctries) {
	for (size in c("l", "m", "s")) {
		download_wrds_table(
			db, "bvd", sprintf("ob_basic_shareholder_info_%s", size), 
			parquet_file = sprintf(
				"orbis_basic_shareholder_info_%s_%s.parquet", size, tolower(ctry)
			),
			where_query = sprintf("ctryiso = '%s'", ctry)
		)
	}
}

# Contact info
for (ctry in ctries) {
	for (size in c("l", "m", "s")) {
		download_wrds_table(
			db, "bvd", sprintf("ob_contact_info_%s", size), 
			parquet_file = sprintf(
				"orbis_contact_info_%s_%s.parquet", size, tolower(ctry)
			),
			where_query = sprintf("ctryiso = '%s'", ctry)
		)
	}
}

# --- Disconnect from WRDS -----------------------------------------------------
dbDisconnect(db, shutdown = TRUE)

log_info("Disconnected from WRDS")
