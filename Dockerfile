FROM nfcore/base:1.9

COPY environment.yml /

RUN conda env create -f /environment.yml && conda clean -a

COPY assets/multiqc_plugins /opt/multiqc_plugins

SHELL ["/bin/bash", "--login", "-c"]

COPY bin/* /opt/conda/envs/rnaseq/bin

RUN chmod +x /opt/conda/envs/rnaseq/bin/*

RUN conda activate rnaseq && cd /opt/multiqc_plugins && python setup.py install

ENV PATH /opt/conda/envs/rnaseq/bin:$PATH