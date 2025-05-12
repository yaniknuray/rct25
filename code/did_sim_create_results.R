suppressWarnings(suppressPackageStartupMessages({
	library(logger)
}))

source("code/did_sim_utils.R")

set.seed(42)

NSIM_RUNS <- 1000
RESULTS_FNAME <- "data/generated/did_sim_results.rds"

log_info("Running a DiD analysis on 1,000 samples. This will take a while.")
sim_results <- run_sims(NSIM_RUNS)
log_info("Done. Saving results to {RESULTS_FNAME}")

saveRDS(sim_results, RESULTS_FNAME)
