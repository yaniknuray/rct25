suppressWarnings(suppressPackageStartupMessages({
	library(tidyverse)
	library(arrow)
	library(logger)
}))

vars <- c("fias", "ifas", "tfas", "ofas", "cuas", "stok", "debt", "ocas", 
					"cash", "toas", "shfd", "capi", "osfd", "ncli", "ltdb", "oncl", 
					"prov", "culi", "loan", "cred", "ocli", "tshf", "wkca", "ncas", 
					"enva", "empl", "opre", "turn", "cost", "gros", "oope", "oppl", 
					"fire", "fiex", "fipl", "plbt", "taxa", "plat", "exre", "exex", 
					"extr", "pl", "expt", "mate", "staf", "depr", "inte", "rd")


# --- Read Orbis parquet files -------------------------------------------------

log_info("Reading Orbis parquet data")
basic_sholder_info <- bind_rows(
	lapply(c("l", "m", "s"), function(s) read_parquet(sprintf(
		"data/pulled/orbis_basic_shareholder_info_%s_de.parquet", s
	)))
)
contact_info <- bind_rows(
	lapply(c("l", "m", "s"), function(s) read_parquet(sprintf(
		"data/pulled/orbis_contact_info_%s_de.parquet", s
	)))
)
legal_info <- bind_rows(
	lapply(c("l", "m", "s"), function(s) read_parquet(sprintf(
		"data/pulled/orbis_legal_info_%s_de.parquet", s
	)))
)
ind_s <- read_parquet("data/pulled/orbis_ind_g_fins_eur_s_de.parquet")
ind_m <- read_parquet("data/pulled/orbis_ind_g_fins_eur_m_de.parquet")
ind_l <- read_parquet("data/pulled/orbis_ind_g_fins_eur_l_de.parquet")
log_info("Orbis parquet data read")


# --- Prepare panel -------------------------------------------------

clean_financial_data <- function(df) {
	df <- df %>%
		filter(
			toas > 0,
			nr_months == "12",
		) %>%
		mutate(year = year(closdate)) %>%
		select(
			ctryiso, bvdid, year, closdate, conscode, filing_type, accpractice, 
			audstatus, source, category_of_company,
			all_of(vars)
		) %>% 
		mutate(
			cc_rank = if_else(
				conscode == "C1", 4,
				ifelse(
					conscode == "C2", 3, ifelse(conscode == "U1", 2, 1))
			),
			ft_rank = ifelse(filing_type == "Annual report", 2, 1)
		) %>% 
		group_by(bvdid, closdate) %>%
		filter(cc_rank == max(cc_rank, na.rm = TRUE)) %>%
		filter(ft_rank == max(ft_rank, na.rm = TRUE)) %>%
		group_by(bvdid, year) %>%
		filter(cc_rank == max(cc_rank, na.rm = TRUE)) %>%
		filter(closdate == max(closdate, na.rm = TRUE)) %>%
		select(-cc_rank, -ft_rank) 

	clean <- df %>% filter(n() == 1)
	if (nrow(clean) != nrow(df)) {
		log_info(
			"Found {nrow(df) - nrow(clean)} duplicates. ", 
			"Will use observations with fewer missing values"
		)
		dups <- df %>% filter(n() > 1) %>%
			mutate(
				n_missing = rowSums(across(everything(),~ is.na(.x)))
			) %>%
			filter(n_missing == min(n_missing, na.rm = TRUE)) %>%
			select(-n_missing)
		df <- bind_rows(clean, dups) %>%
			arrange(bvdid, year)
	} else {
		df <- clean  %>% arrange(bvdid, year)
	}
	
	dups <- df %>% filter(n() > 1) 
	
	if (nrow(dups) > 0) {
		log_error("{nrow(dups)} duplicates found. This should not happen")
		stop()
	}
	df %>% ungroup()
}

log_info("Processing financial data of large firms")
fi_l <- clean_financial_data(ind_l)
log_info("Processing financial data of medium firms")
fi_m <- clean_financial_data(ind_m)
log_info("Processing financial data of small firms")
fi_s <- clean_financial_data(ind_s)

log_info("Pooling financial data")
fi <- bind_rows(fi_l, fi_m, fi_s)
dups <- fi %>%
	group_by(bvdid, year) %>%
	filter(n() > 1)
if (nrow(dups) > 0) {
	log_error("{nrow(dups) duplicates found. This should not happen")
	stop()
}
log_info("Financial data merged ({format(nrow(fi), big.mark = ',')} obs).")

log_info("Preparing remaining data")
li <- legal_info %>%
	select(
		ctryiso, bvdid, category_of_company, dateinc, historic_statusdate,
		historic_status_str, legalfrm, listed
	)
bsi <- basic_sholder_info %>%
  select(ctryiso, bvdid, `_9427`) %>%
  rename(indepind = `_9427`) 
ci <- contact_info %>%
	select(
		ctryiso, bvdid, name_native, name_internat, 
		addr_native, postcode, city_native
	)

log_info("Merging data...")
panel <- fi %>% left_join(bsi, by = c("ctryiso", "bvdid")) %>%
	left_join(ci, by = c("ctryiso", "bvdid")) %>%
	left_join(
      li %>% select(ctryiso, bvdid, historic_status_str, legalfrm, listed), 
      by = c("ctryiso", "bvdid")
    ) %>%
    rename(status_str = historic_status_str) %>%
    select(
      ctryiso, bvdid, name_native, name_internat, category_of_company, 
      addr_native, postcode, city_native,
      status_str, legalfrm, indepind, listed,
      year, closdate, conscode, filing_type, accpractice, audstatus, source,
      all_of(vars) 
    ) %>%
    arrange(ctryiso, bvdid, year)
log_info("done ({format(nrow(panel), big.mark = ',')} obs)")

fname <- "data/generated/orbis_panel_de.rds"
saveRDS(panel, fname)
log_info("Orbis panel data saved to '{fname}'.")

