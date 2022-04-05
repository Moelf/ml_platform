FROM centos:7

LABEL maintainer Ilija Vukotic <ivukotic@cern.ch>

RUN  mkdir -p /etc/grid-security/certificates 
RUN  mkdir -p /etc/grid-security/vomsdir


# # optional: prefill certificates and vomsdir.
#   GRIDSECURITY="/cvmfs/oasis.opensciencegrid.org/mis/osg-wn-client/current/el7-x86_64/etc/grid-security"
#   if [ -d $GRIDSECURITY ]; then
#     cd $GRIDSECURITY
#     tar chf - certificates vomsdir | (cd $SINGULARITY_ROOTFS/etc/grid-security; tar xf -)
#   fi


RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN yum install -y centos-release-scl-rh
RUN yum update -y

# Install dependencies for Boost and ROOT and a login environment
RUN  yum install -y curl libcurl libcurl-devel \
        mariadb mariadb-libs mariadb-devel \
        make wget git patch gcc gcc-c++ gcc-gfortran gdb python-devel python3-devel cmake cmake3 \
        binutils net-tools hostname vi vim-enhanced strace telnet iputils which openssh-clients tcsh \
        libX11-devel libXpm-devel libXft-devel libXext-devel \
        openssl-devel pcre-devel mesa-libGL-devel \
        mesa-libGLU-devel glew-devel fftw-devel graphviz-devel \
        avahi-compat-libdns_sd-devel libxml2-devel gls-devel blas-devel \
        bazel http-parser nodejs perl-Digest-MD5 zlib-devel perl-ExtUtils-MakeMaker gettext \
        libffi-devel pandoc \
        emacs bzip2 zip unzip lrzip tree ack screen tmux emacs-nox \
        libarchive-devel fuse-sshfs jq graphviz \
        dvipng xterm file \
        munge-libs tcl expect \
        xrootd-client xrootd-client-libs xrootd-client-devel davix davix-devel rclone \
        devtoolset-7-gcc-c++

# Python 2  
RUN curl -o /tmp/get-pip.py https://bootstrap.pypa.io/pip/2.7/get-pip.py
RUN python2 /tmp/get-pip.py
RUN rm /tmp/get-pip.py

RUN python2 -m pip --no-cache-dir install \
        ipykernel \
        zmq \
        numpy \
        scipy \
        wheel \
        requests \
        urllib3 \
        wcwidth==0.1.9

RUN  python2 -m pip --no-cache-dir install \
        matplotlib==1.2.0 \
        pyparsing \
        xrootd \
        uproot \
        metakernel


# Python 3
RUN yum install -y python3-pip 
RUN python3 -m pip install --upgrade pip setuptools

RUN export PYCURL_SSL_LIBRARY=openssl
RUN python3 -m pip --no-cache-dir install \
        jupyterlab \
        ipykernel \
        jupyterhub \
        pyyaml \
        pycurl \
        python-oauth2 \
        wheel \
        cryptography \
        urllib3==1.24.3 \
        mysqlclient

RUN python3 -m pip --no-cache-dir install \
        uproot \
        xrootd \
        h5py \
        iminuit \
        pydot \
        jupyter \
        jupyter-tensorboard \
        metakernel \
        zmq \
        matplotlib \
        dask[complete] \
        xlrd xlwt openpyxl \
        mplhep atlasify scikit-hep

# allow arrow key navigation in terminal vim
RUN echo 'set term=builtin_ansi' >> /etc/vimrc




# Depend on the following two bind mounts to provide ROOT and kernels for ROOT C++ and PyROOT
RUN mkdir /cvmfs /mycvmfs
# ln -s /cvmfs/atlas.sdcc.bnl.gov/jupyter/t3s/common/kernels/pyroot3 /usr/local/share/jupyter/kernels/pyroot3
# ln -s /cvmfs/atlas.sdcc.bnl.gov/jupyter/t3s/common/kernels/pyroot2 /usr/local/share/jupyter/kernels/pyroot2
# ln -s /cvmfs/atlas.sdcc.bnl.gov/jupyter/t3s/common/kernels/rootcpp /usr/local/share/jupyter/kernels/rootcpp

# System wide Anaconda

RUN yum install -y libXcomposite libXcursor libXi libXtst libXrandr alsa-lib \
        mesa-libEGL libXdamage mesa-libGL libXScrnSaver
RUN yum clean all

RUN curl -o /tmp/anaconda3.sh https://repo.anaconda.com/archive/Anaconda3-2020.11-Linux-x86_64.sh
RUN bash /tmp/anaconda3.sh -b -p /opt/anaconda3
RUN rm /tmp/anaconda3.sh

RUN . /opt/anaconda3/etc/profile.d/conda.sh

RUN mkdir -p /usr/local/share/jupyter/launch


# rapids-0.18
RUN . /opt/anaconda3/etc/profile.d/conda.sh && \
        conda create -n rapids-0.18 -c rapidsai -c nvidia -c conda-forge -c defaults \
        rapids-blazing=0.18 python=3.7 cudatoolkit=10.1 \
        ipykernel uproot3 xrootd
RUN mkdir /usr/local/share/jupyter/kernels/rapids-0.18
RUN cp -p /opt/anaconda3/share/jupyter/kernels/python3/logo-32x32.png /usr/local/share/jupyter/kernels/rapids-0.18
RUN cp -p /opt/anaconda3/share/jupyter/kernels/python3/logo-64x64.png /usr/local/share/jupyter/kernels/rapids-0.18
COPY kernel.json /usr/local/share/jupyter/kernels/rapids-0.18/kernel.json
COPY rapids-0.18.sh /usr/local/share/jupyter/launch/rapids-0.18.sh
RUN chmod 755 /usr/local/share/jupyter/launch/rapids-0.18.sh


RUN . /opt/anaconda3/etc/profile.d/conda.sh && \
        conda create -n tf-keras-gpu -c conda-forge -c defaults \
        tensorflow-gpu==2.2.0 keras==2.3.1 \
        ipykernel uproot3 xrootd
RUN mkdir /usr/local/share/jupyter/kernels/tf-keras-gpu
RUN cp -p /opt/anaconda3/share/jupyter/kernels/python3/logo-32x32.png /usr/local/share/jupyter/kernels/tf-keras-gpu
RUN cp -p /opt/anaconda3/share/jupyter/kernels/python3/logo-64x64.png /usr/local/share/jupyter/kernels/tf-keras-gpu

COPY kernel-gpu.json /usr/local/share/jupyter/kernels/tf-keras-gpu/kernel.json
COPY tf-keras-gpu.sh /usr/local/share/jupyter/launch/tf-keras-gpu.sh
RUN chmod 755 /usr/local/share/jupyter/launch/tf-keras-gpu.sh

RUN . /opt/anaconda3/etc/profile.d/conda.sh && \
        conda clean --all --force-pkgs-dirs -y

# build info
RUN echo "Timestamp:" `date --utc` | tee /image-build-info.txt

CMD ["jupyter lab"]


# COPY environment /environment
# COPY exec        /.exec
# COPY run         /.run
# COPY shell       /.shell
# RUN chmod 755 .exec .run .shell

# COPY private_jupyter_notebook_config.py /root/.jupyter/jupyter_notebook_config.py

# RUN jupyter serverextension enable --py jupyterlab --sys-prefix

#execute service
# CMD ["/.run"]