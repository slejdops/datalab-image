#!/bin/bash

set -x

echo "Copy files from pre-load directory into home "
#cp --update -r -v /pre-home/. /home/jovyan
cp -r -v /pre-home/. /home/jovyan

if [ -e "/opt/app/environment.yml" ]; then
    echo "environment.yml found. Installing packages"
    /opt/conda/bin/conda env update -f /opt/app/environment.yml
else
    echo "no environment.yml"
fi

if [ "$EXTRA_CONDA_PACKAGES" ]; then
    echo "EXTRA_CONDA_PACKAGES environment variable found.  Installing."
    /opt/conda/bin/conda install $EXTRA_CONDA_PACKAGES
fi

if [ "$EXTRA_PIP_PACKAGES" ]; then
    echo "EXTRA_PIP_PACKAGES environment variable found.  Installing".
    /opt/conda/bin/pip install $EXTRA_PIP_PACKAGES
fi

#if [ "$GCSFUSE_BUCKET" ]; then
#    echo "Mounting $GCSFUSE_BUCKET to /gcs"
#    /opt/conda/bin/gcsfuse $GCSFUSE_BUCKET /gcs --background
#fi




# check if we are on Sanger internal network and datalab.malariagen.sanger.ac.uk resolves

dig +timeout=1  +short @172.18.255.1 datalab.malariagen.sanger.ac.uk
rc=$?

if [[ $rc = 0 ]];


then
        echo "DNS OK"
echo "nameserver 172.18.255.1" > /tmp/resolv.conf
cat /etc/resolv.conf >> /tmp/resolv.conf
sudo cp /tmp/resolv.conf /etc/resolv.conf

mkdir /home/jovyan/nfs

sudo mount 10.233.41.41:/ /home/jovyan/nfs

else
 echo "DNS record for datalab not found"

fi
$@

