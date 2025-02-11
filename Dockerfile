FROM rocker/geospatial:latest
COPY . /workdir

RUN R -e "remotes::install_github('BirdLifeInternational/track2kba')"
