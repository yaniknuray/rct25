suppressWarnings(suppressPackageStartupMessages({
	library(tidyverse)
	library(logger)
}))

log_info("Reading German Orbis panel")
ob <- readRDS("data/generated/orbis_panel_de.rds")

log_info("Filtering Berlin observations")
bp <- ob %>% filter(city_native == "Berlin")

fname <- "data/precomputed/orbis_panel_berlin.rds"
log_info(
	"Saving Berlin panel ({format(nrow(bp), big.mark = ',')} obs) to '{fname}'"
)
saveRDS(bp, fname)

log_info("done")