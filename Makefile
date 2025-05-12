# If you are new to Makefiles: https://makefiletutorial.com
 
# Commands

RSCRIPT := Rscript --encoding=UTF-8
PYTHON := python


# Main targets

ACZ2018_FIGURE := output/acz2018_figure.pdf
ACZ2018_DID_FIN := output/acz2018_did_fin.docx
ACZ2018_DID_MKT := output/acz2018_did_mkt.docx
ACZ2018_TABLE5 := output/acz2018_table5.pdf
ORBIS_PANEL_BERLIN := data/generated/orbis_panel_berlin.rds
DID_SIMULATION := output/did_simulation.pdf

# Data Targets

ORBIS_DATA := data/pulled/orbis_ind_g_fins_eur_l_de.parquet \
	data/pulled/orbis_ind_g_fins_eur_m_de.parquet \
	data/pulled/orbis_ind_g_fins_eur_s_de.parquet \
	data/pulled/orbis_basic_shareholder_info_l_de.parquet \
	data/pulled/orbis_basic_shareholder_info_m_de.parquet \
	data/pulled/orbis_basic_shareholder_info_s_de.parquet \
	data/pulled/orbis_legal_info_l_de.parquet \
	data/pulled/orbis_legal_info_m_de.parquet \
	data/pulled/orbis_legal_info_s_de.parquet \
	data/pulled/orbis_contact_info_l_de.parquet \
	data/pulled/orbis_contact_info_m_de.parquet \
	data/pulled/orbis_contact_info_s_de.parquet

ORBIS_PANEL_DE := data/generated/orbis_panel_de.rds

DID_SIM_RESULTS := data/generated/did_sim_results.rds

# Materials needed for main targets

ALL_TARGETS := $(ACZ2018_FIGURE) $(ACZ2018_DID_FIN) $(ACZ2018_DID_MKT) \
	$(ACZ2018_TABLE5) $(ORBIS_PANEL_BERLIN) $(DID_SIMULATION)


# Phony targets

.phony: all

all: $(ALL_TARGETS)

clean:
	rm -f $(ALL_TARGETS)
	rm -f data/generated/*
	rm -f data/temp/*
	rm -f *.log

dist-clean: clean
	rm -f data/precomputed/*
	rm -f data/pulled/*

	
# Recipes

## Data Recipes

$(ORBIS_DATA): config.env code/pull_wrds_data.R
	$(RSCRIPT) code/pull_wrds_data.R
	
$(ORBIS_PANEL_DE): $(ORBIS_DATA) code/create_orbis_panel_de.R
	$(RSCRIPT) code/create_orbis_panel_de.R

$(ORBIS_PANEL_BERLIN): $(ORBIS_PANEL_DE) code/create_orbis_panel_berlin.R
	$(RSCRIPT) code/create_orbis_panel_berlin.R
	
$(DID_SIM_RESULTS): code/did_sim_utils.R code/did_sim_create_results.R
	$(RSCRIPT) code/did_sim_create_results.R
	
## Output Recipes
	
$(ACZ2018_FIGURE): data/external/acz2018.dta scripts/create_acz2018_figure.R
	$(RSCRIPT) scripts/create_acz2018_figure.R

$(ACZ2018_DID_FIN) $(ACZ2018_DID_MKT): data/external/acz2018.dta \
	scripts/create_acz2018_did.R
	$(RSCRIPT) scripts/create_acz2018_did.R
	
$(ACZ2018_TABLE5): data/external/acz2018.dta scripts/create_acz2018_table5.qmd
	quarto render scripts/create_acz2018_table5.qmd -o acz2018_table5.pdf --quiet

$(DID_SIMULATION): $(DID_SIM_RESULTS) scripts/did_simulation.qmd
	quarto render scripts/did_simulation.qmd -o did_simulation.pdf --quiet
 