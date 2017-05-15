#!/bin/bash
#
# Build manylinux1 wheels for HTSeq. Based on the example at
# <https://github.com/pypa/python-manylinux-demo>
#
# It is best to run this in a fresh clone of the repository!
#
# Run this within the repository root:
#   docker run --rm -v $(pwd):/io quay.io/pypa/manylinux1_x86_64 /io/buildwheels.sh
#
# The wheels will be put into the wheelhouse/ subdirectory.
#
# For interactive tests:
#   docker run -it -v $(pwd):/io quay.io/pypa/manylinux1_x86_64 /bin/bash

set -xeuo pipefail

# For convenience, if this script is called from outside of a docker container,
# it starts a container and runs itself inside of it.
if ! grep -q docker /proc/1/cgroup; then
  # We are not inside a container
  exec docker run --rm -v $(pwd):/io quay.io/pypa/manylinux1_x86_64 /io/$0
fi

# These are needed by pysam, maybe not by us
#yum install -y zlib-devel bzip2-devel xz-devel

# Python 2.6 is not supported
rm -r /opt/python/cp26*

# Python 3.3 is not supported:
rm -r /opt/python/cp33*

# Without libcurl support, htslib can open files from HTTP and FTP URLs.
# With libcurl support, it also supports HTTPS and S3 URLs, but libcurl needs a
# current version of OpenSSL, and we do not want to be responsible for
# updating the wheels as soon as there are any security issues. So disable
# libcurl for now.
# See also <https://github.com/pypa/manylinux/issues/74>.
#
#export HTSLIB_CONFIGURE_OPTIONS="--disable-libcurl"

PYBINS="/opt/python/*/bin"
for PYBIN in ${PYBINS}; do
    ${PYBIN}/pip install -r /io/requirements.txt
    ${PYBIN}/pip wheel /io/ -w wheelhouse/
    # FIXME
    break
done

for whl in wheelhouse/*.whl; do
    auditwheel repair -L . $whl -w /io/wheelhouse/
done

# Created files are owned by root, so fix permissions.
chown -R --reference=/io/setup.py /io/wheelhouse/

ls /io/wheelhouse

# TODO Install packages and test them
#for PYBIN in ${PYBINS}; do
#    ${PYBIN}/pip install HTSeq --no-index -f /io/wheelhouse
#    (cd $HOME; ${PYBIN}/nosetests ...)
#done
