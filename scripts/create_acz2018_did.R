# ------------------------------------------------------------------------------
# Code to estimate a DiD-type profit effect of
# Anderson, Chandy, and Zhia (2018): 
# Pathways to Profits: The Impact of Marketing vs. Finance Skills 
# on Business Performance
# https://pubsonline.informs.org/doi/suppl/10.1287/mnsc.2017.2920
# Compare to Table 5 of Anderson et. al (p. 5571)
# ------------------------------------------------------------------------------

suppressWarnings(suppressPackageStartupMessages({
	library(tidyverse)
	library(haven)
	library(fixest)
	library(modelsummary)
}))

# Data can be obtained at 
# https://pubsonline.informs.org/doi/suppl/10.1287/mnsc.2017.2920
raw_dta <- read_dta("data/external/acz2018.dta")


TREATMENTS <- c("Finance/Accounting", "Marketing")

# The following constants are as in the original code
# provided by the authors - Thanks!
CONTROLS <- c(
	"Gender", "Age", "Children_total", "Race_SAblackcolored",
	"Race_Foreigner", "Educ_high", "Operating_yearstotal",
	"CapStart_total", "Activity_Hours", "pre_Loan_formal",
	"pre_Structure_type", "pre_Employees1_composite", "FormalReg"
)
INDFE <- c(
	"Ind2_SIC15", "Ind2_SIC17", "Ind2_SIC23", "Ind2_SIC25",
	"Ind2_SIC34", "Ind2_SIC41", "Ind2_SIC54", "Ind2_SIC56",
	"Ind2_SIC57", "Ind2_SIC58", "Ind2_SIC59", "Ind2_SIC72",
	"Ind2_SIC73", "Ind2_SIC75", "Ind2_SIC76", "Ind2_SIC83"
)
YVARS <- c(
	"Profits1_aidedrecall_w1", "Profits2_anchored_w1",
	"Profits3_composite_w1", "Profits3_composite_IHS"
)

# We only do this for the final survey round
df <- raw_dta %>%
	filter(Survivorship==1, T_survey_round==3) %>% 
	mutate(
		firm_id = N_firm_id,
		tment = case_when(
			Treatment_FIN == 1 ~ "Finance/Accounting",
			Treatment_MKT == 1 ~ "Marketing",
			TRUE ~ "Control"
		),
		Profits1_aidedrecall_w1__pre = pre_Profits1_aidedrecall_w1,
		Profits1_aidedrecall_w1__post = Profits1_aidedrecall_w1,
		Profits2_anchored_w1__pre = pre_Profits2_anchored_w1,
		Profits2_anchored_w1__post = Profits2_anchored_w1,
		Profits3_composite_w1__pre = pre_Profits3_composite_w1,
		Profits3_composite_w1__post = Profits3_composite_w1,
		Profits3_composite_IHS__pre = pre_Profits3_composite_IHS,
		Profits3_composite_IHS__post = Profits3_composite_IHS
	) %>%
	select(
		firm_id, tment, ends_with("__pre"), ends_with("__post"), 
		all_of(c(CONTROLS, INDFE))
	) %>%
	pivot_longer(
		-all_of(c("firm_id", "tment", CONTROLS, INDFE)), 
		names_to = c(".value", "period"), names_sep = "__"
	)

estimate_did_models <- function(y, tm) {
	smp <- df %>%
		filter(tment %in% c("Control", tm)) %>%
		mutate(
			tment = 1*(tment == tm),
			post = 1*(period == "post"),
			treated = tment * post
		)
	
	did_plain <- feols(
		as.formula(paste(y, "~ tment*post")), se = "hetero", data = smp
	)
	
	did_ctrls <- feols(
		as.formula(paste(y, "~ tment*post +", paste(c(CONTROLS, INDFE), collapse = " + "))), 
		se = "hetero", data = smp
	)
	
	did_twfe <- feols(
		as.formula(paste(y, "~ treated | firm_id + period")), data = smp
	)
	
	rv <- list(
		`DiD Plain` = did_plain, `DiD with Controls` = did_ctrls,
		`Twoway Fixed Effects DiD` = did_twfe
	)
	
	names(rv) <- paste(
		tm, y, c("DiD Plain", "DiD with controls", "Two-way Fixed Effects")
	)
	rv
}

create_reg_table <- function(mods, fname = "default") {
	# Industry Fixed Effects are omitted from Table
	modelsummary(
		mods, fname,
		stars = c(`***` = 0.01, `**` = 0.05, `*` = 0.1),
		coef_map = c(
			"(Intercept)", "tment", "post", "tment:post", "treated", CONTROLS
		)
	)
}

fin_mods <- estimate_did_models(YVARS[1], TREATMENTS[1])
# To display the table as HTML within RStudio, run:
# create_reg_table(fin_mods)
create_reg_table(fin_mods, "output/acz2018_did_fin.docx")

mkt_mods <- estimate_did_models(YVARS[1], TREATMENTS[2])
create_reg_table(mkt_mods, "output/acz2018_did_mkt.docx")

