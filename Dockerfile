FROM islasgeci/base:1.0.0
COPY . /workdir
RUN apt update && apt install --yes \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    libudunits2-dev \
    netcdf-bin

RUN R -e "remotes::install_version('terra', '1.7-3', repos = c('https://rspatial.r-universe.dev', 'https://cloud.r-project.org'))"
RUN R -e "remotes::install_github('BirdLifeInternational/track2kba')"
