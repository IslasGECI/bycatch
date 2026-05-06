FROM islasgeci/base:latest
COPY . /workdir
COPY ./.R/Makevars /root/.R/Makevars
RUN apt update && apt install --yes \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    libudunits2-dev \
    libuv1 \
    netcdf-bin
RUN make install
