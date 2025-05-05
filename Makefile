# If you are new to Makefiles: https://makefiletutorial.com
 
# Commands

RSCRIPT := Rscript --encoding=UTF-8
PYTHON := python


# Main targets

ACZ2018_FIGURE := output/acz2018_figure.pdf
ACZ2018_DID_FIN := output/acz2018_did_fin.docx
ACZ2018_DID_MKT := output/acz2018_did_mkt.docx
ORBIS_PANEL_BERLIN := data/precomputed/orbis_panel_berlin.rds

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

# Materials needed for main targets

ALL_TARGETS := $(ACZ2018_FIGURE) $(ACZ2018_DID_FIN) $(ACZ2018_DID_MKT) \
	$(ORBIS_PANEL_BERLIN) 


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
	
## Output Recipes
	
$(ACZ2018_FIGURE): data/external/acz2018.dta scripts/create_acz2018_figure.R
	$(RSCRIPT) scripts/create_acz2018_figure.R

$(ACZ2018_DID_FIN) $(ACZ2018_DID_MKT): data/external/acz2018.dta \
	scripts/create_acz2018_did.R
	$(RSCRIPT) scripts/create_acz2018_did.R

# None yet
