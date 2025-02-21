FROM islasgeci/base:latest
COPY . /workdir
RUN apt update && apt install --yes \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    libudunits2-dev \
    netcdf-bin

RUN R -e "remotes::install_github('BirdLifeInternational/track2kba')"
RUN R -e "remotes::install_github('IslasGECI/testtools', ref='latest')"
