FROM jupyter/base-notebook

USER root
RUN apt-get update \
  && apt-get install -yq --no-install-recommends dnsutils libfuse-dev nano fuse vim git \
  build-essential  openssh-client nfs-common rpcbind inetutils-ping wget \
  nfs-kernel-server runit inotify-tools \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*



USER $NB_USER


RUN conda config --set ssl_verify no

COPY env-linux.yaml /tmp/env-linux.yaml

#COPY binder/environment-pinned-linux.yml /tmp/environment-pinned-linux.yml
#RUN sed  's/malariagen/base/' /tmp/environment-pinned-linux.yml > /tmp/environment.yml
RUN sed  's/malariagen/base/' /tmp/env-linux.yaml > /tmp/environment.yml

COPY pinned /tmp/pinned

ARG tag
RUN echo "image tag is $tag"
ENV IMAGETAG=$tag

RUN echo " ---------------------------------- "
RUN echo "env variable IMAGETAG is ${IMAGETAG}"




# create default scientific Python environment

RUN conda config --add channels pyviz/label/dev
RUN conda config --add channels bokeh/label/dev
RUN conda config --add channels intake
RUN conda config --add channels bioconda
RUN conda config --add channels conda-forge
#RUN conda update --yes conda
RUN cat /tmp/pinned > /opt/conda/conda-meta/pinned

RUN conda env update  --file /tmp/environment.yml --prune




RUN conda clean -afy \
    && find /opt/conda/ -follow -type f -name '*.a' -delete \
    && find /opt/conda/ -follow -type f -name '*.pyc' -delete \
    && find /opt/conda/ -follow -type f -name '*.js.map' -delete


RUN conda install -n base -c conda-forge widgetsnbextension
RUN conda install -n base -c conda-forge ipywidgets
RUN conda install -n base -c conda-forge dask_labextension

# https://github.com/dask/dask-labextension/issues/51    nbserverproxy has been replaced by jupyter-server-proxy

RUN /opt/conda/bin/pip install jupyter-server-proxy

RUN conda  install nb_conda
#RUN conda remove -n base nbserverproxy

#RUN jupyter serverextension enable --py nbserverproxy --sys-prefix


USER root
COPY prepare.sh /usr/bin/prepare.sh
RUN chmod +x /usr/bin/prepare.sh
RUN mkdir /home/$NB_USER/examples && chown -R $NB_USER /home/$NB_USER/examples
RUN mkdir /pre-home && mkdir /pre-home/examples

RUN mkdir /home/$NB_USER/nfs
RUN chown -R $NB_USER /home/$NB_USER/nfs

COPY conda_init /pre-home/.bashrc
COPY conda_init /pre-home/.profile
RUN chown -R $NB_USER /pre-home
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

RUN conda env list

RUN jupyter nbextension enable --sys-prefix --py widgetsnbextension

RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager
RUN jupyter labextension install @jupyterlab/hub-extension
RUN jupyter labextension install @pyviz/jupyterlab_pyviz
RUN jupyter labextension install dask-labextension

RUN jupyter labextension list

ENTRYPOINT ["tini", "--", "/usr/bin/prepare.sh"]
CMD ["start.sh jupyter lab"]

