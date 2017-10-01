# AWS Lambda functions use the AmazonLinux distirbution as their runtime,
# which means that lambda functions that include dependent packages must
# be built on AmazonLinux. This presents a problem for developing Python
# functions that use Python3, as there is no amazonlinux-python3 docker
# image available from Amazon themselves. This Dockerfile will build an
# image that includes the 3.6 Python runtime.
#
# The default entrypoint is 'make' - this is based on an opinionated 
# assumption that the container will be run from a directory that contains
# a Makefile. 
# 
# This image is based on the work in https://github.com/renanivo/lambda-s3-sftp
#
FROM amazonlinux:latest
LABEL maintainer "YunoJuno <code@yunojuno.com>"

# install pre-requisites
RUN yum -y groupinstall development && \
    yum -y install zlib-devel openssl-devel wget

# Need to install OpenSSL also to avoid SSL errors with pip
RUN wget https://github.com/openssl/openssl/archive/OpenSSL_1_0_2l.tar.gz && \
    tar -zxvf OpenSSL_1_0_2l.tar.gz && \
    cd openssl-OpenSSL_1_0_2l/ && \

    ./config shared && \
    make && \
    make install && \
    export LD_LIBRARY_PATH=/usr/local/ssl/lib/ && \

    cd .. && \
    rm OpenSSL_1_0_2l.tar.gz && \
    rm -rf openssl-OpenSSL_1_0_2l/

# Install Python 3.6
RUN wget https://www.python.org/ftp/python/3.6.0/Python-3.6.0.tar.xz && \
    tar xJf Python-3.6.0.tar.xz && \
    cd Python-3.6.0 && \

    ./configure && \
    make && \
    make install && \

    cd .. && \
    rm Python-3.6.0.tar.xz && \
    rm -rf Python-3.6.0

# Create and activate a virtualenv, so we isolate the project libs
RUN pip3 install pip-tools virtualenv && \
    virtualenv -p python3 /.venv/lambda && \
    source /.venv/lambda/bin/activate && \
    echo 'source /.venv/lambda/bin/activate' >> ~/.bashrc

VOLUME ["/lambda"]
WORKDIR "/lambda"
ENTRYPOINT ["make"]
