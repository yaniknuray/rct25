ARG VARIANT="4.3"
FROM ghcr.io/rocker-org/devcontainer/tidyverse:${VARIANT}

RUN install2.r --error --skipinstalled -n -1 \
        haven \
        fixest \
        modelsummary \
        gt \
        flextable \
        marginaleffects \
    && rm -rf /tmp/downloaded_packages

RUN quarto install tinytex --update-path

# Install Python packages
# COPY requirements.txt /tmp/pip-tmp/
# RUN python3 -m pip --disable-pip-version-check --no-cache-dir install -r /tmp/pip-tmp/requirements.txt