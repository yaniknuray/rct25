FROM rocker/verse:4.3

RUN install2.r --error --skipinstalled -n -1 \
        haven \
        fixest \
        modelsummary \
        gt \
        flextable \
        marginaleffects \
        pandoc \
        languageserver \
        logger \
        duckdb \
        hms \
        arrow \
    && rm -rf /tmp/downloaded_packages

# vscDebugger (needed for VS code R debugger extension is not on CRAN)
RUN Rscript -e 'install.packages("vscDebugger", repos = "https://manuelhentschel.r-universe.dev")'

# Install Python packages
# COPY requirements.txt /tmp/pip-tmp/
# RUN python3 -m pip --disable-pip-version-check --no-cache-dir install -r /tmp/pip-tmp/requirements.txt