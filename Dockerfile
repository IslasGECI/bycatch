FROM islasgeci/base:latest
COPY . /workdir
RUN apt update && apt install --yes \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    libudunits2-dev \
    netcdf-bin

RUN R -e "remotes::install_github('r-quantities/units')"
RUN R -e "remotes::install_version('s2', version = '1.1.7')"
RUN R -e "install.packages('sf', dependencies = c('Imports','LinkingTo'))"
RUN R -e "remotes::install_github('BirdLifeInternational/track2kba')"
RUN R -e "remotes::install_github('IslasGECI/testtools')"
RUN R -e "remotes::install_github('IslasGECI/optparse', ref='latest')"
RUN R -e "install.packages(c('rjson', 'adehabitatHR','dafishr'), repos='http://cran.rstudio.com')"
