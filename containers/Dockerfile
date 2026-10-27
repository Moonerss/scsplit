FROM mambaorg/micromamba:1.5.10

LABEL org.opencontainers.image.title="scsplit runtime"
LABEL org.opencontainers.image.description="Runtime dependencies for all scsplit Nextflow processes"

COPY --chown=$MAMBA_USER:$MAMBA_USER containers/environment.yml /tmp/environment.yml

RUN micromamba install --yes --name base --file /tmp/environment.yml \
    && micromamba clean --all --yes \
    && rm /tmp/environment.yml

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TMPDIR=/tmp

WORKDIR /workspace
