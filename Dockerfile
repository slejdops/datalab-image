FROM jupyter/base-notebook:4417b81d04b7

USER root
RUN apt-get update \
  && apt-get install -yq --no-install-recommends dnsutils libfuse-dev nano fuse vim git build-essential  openssh-client \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

USER $NB_USER
RUN conda config --set ssl_verify no
COPY conda.txt /conda.txt
COPY pip.txt /pip.txt


RUN conda config --add channels conda-forge
RUN conda config --add channels pyviz/label/dev
RUN conda config --add channels bokeh/label/dev
RUN conda config --add channels intake
RUN conda config --add channels bioconda
RUN conda update --yes conda


RUN conda install --yes  \
    -c pyviz/label/dev \
    -c bokeh/channel/dev \
    -c intake \
    -c conda-forge \
    -c bioconda \
    --file /conda.txt \
    && conda clean -afy \
    && find /opt/conda/ -follow -type f -name '*.a' -delete \
    && find /opt/conda/ -follow -type f -name '*.pyc' -delete \
    && find /opt/conda/ -follow -type f -name '*.js.map' -delete \
    && find /opt/conda/lib/python*/site-packages/bokeh/server/static -follow -type f -name '*.js' ! -name '*.min.js' -delete


RUN pip install --upgrade pip

RUN pip install -r /pip.txt

RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager \
                                 @jupyterlab/hub-extension \
                                 @pyviz/jupyterlab_pyviz
RUN jupyter labextension install dask-labextension

RUN jupyter serverextension enable --py nbserverproxy --sys-prefix

USER root
COPY prepare.sh /usr/bin/prepare.sh
RUN chmod +x /usr/bin/prepare.sh
RUN mkdir /home/$NB_USER/examples && chown -R $NB_USER /home/$NB_USER/examples
RUN mkdir /pre-home && mkdir /pre-home/examples && chown -R $NB_USER /pre-home
COPY examples/ /pre-home/examples/

ENV DASK_CONFIG=/home/$NB_USER/config.yaml
COPY config.yaml /pre-home
COPY worker-template.yaml /pre-home

RUN mkdir /gcs && chown -R $NB_USER /gcs
RUN mkdir /opt/app

# Add NB_USER to sudo
RUN echo "$NB_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/notebook
RUN sed -ri "s#Defaults\s+secure_path=\"([^\"]+)\"#Defaults secure_path=\"\1:$CONDA_DIR/bin\"#" /etc/sudoers
USER $NB_USER

ENTRYPOINT ["tini", "--", "/usr/bin/prepare.sh"]
CMD ["start.sh jupyter lab"]

