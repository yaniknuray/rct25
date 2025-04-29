FROM rocker/verse:4.3

RUN install2.r --error --skipinstalled -n -1 \
        haven \
        fixest \
        modelsummary \
        gt \
        flextable \
        marginaleffects \
        pandoc \
    && rm -rf /tmp/downloaded_packages

# Install Python packages
# COPY requirements.txt /tmp/pip-tmp/
# RUN python3 -m pip --disable-pip-version-check --no-cache-dir install -r /tmp/pip-tmp/requirements.txt