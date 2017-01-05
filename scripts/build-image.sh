#!/usr/bin/env sh

# Exit inmediately if a command fails
set -e

# With a little help from my friends
. /usr/share/vx-docker-internal/ubuntu-base/library.sh

# Let's set some defaults here
XENIAL_REPO="deb http://archive.ubuntu.com/ubuntu/ xenial main universe multiverse"
XENIAL_UPDATES_REPO="deb http://archive.ubuntu.com/ubuntu/ xenial-updates main universe multiverse"
XENIAL_SECURITY_REPO="deb http://archive.ubuntu.com/ubuntu/ xenial-security main universe multiverse"
DPKG_PRE_DEPENDS="wget ca-certificates"
DPKG_DEPENDS="bzr \
              git \
              mercurial \
              bash-completion \
              apt-transport-https \
              curl \
              wget \
              htop \
              locate \
              lsof \
              multitail \
              tmux \
              unzip \
              vim \
              vim-nox \
              w3m \
              openssl \
              openssh-client \
              postgresql-client \
              postgresql-common \
              python \
              python-setuptools"
DPKG_UNNECESSARY="libpython3.4 \
                  libpython3.4-minimal"
PIP_OPTS="--upgrade \
          --no-cache-dir"
PIP_DEPENDS="pyopenssl \
             psycopg2 \
             ndg-httpsclient \
             pyasn1 \
             PyGithub \
             merge-requirements \
             pip-tools \
             click \
             supervisor"
PIP_DPKG_BUILD_DEPENDS="libpq-dev \
                        python-dev \
                        libffi-dev \
                        libssl-dev \
                        gcc"

# Dpkg, please always install configurations from upstream, be fast
# and no questions asked.
{
    echo 'force-confmiss'
    echo 'force-confnew'
    echo 'force-overwrite'
    echo 'force-unsafe-io'
} | tee /etc/dpkg/dpkg.cfg.d/100-vauxoo-dpkg > /dev/null

# Apt, don't give me translations, assume always a positive answer,
# don't fill my image with recommended stuff i didn't told you to install,
# be permissive with packages without visa.
{
    echo 'Acquire::Languages "none";'
    echo 'Apt::Get::Assume-Yes "true";'
    echo 'Apt::Install-Recommends "false";'
    echo 'Apt::Get::AllowUnauthenticated "true";'
    echo 'Dpkg::Post-Invoke { "/usr/share/vx-docker-internal/ubuntu-base/clean-image.sh"; }; '
} | tee /etc/apt/apt.conf.d/100-vauxoo-apt > /dev/null

# This will setup our default locale.
# Setting these three variables will ensure we have a proper locale environment
update-locale LANG=${LANG} LANGUAGE=${LANG} LC_ALL=${LANG}

# Configure apt sources so we can use multiverse section from repo
conf_aptsources "${XENIAL_REPO}" "${XENIAL_UPDATES_REPO}" "${XENIAL_SECURITY_REPO}"

# Upgrade system and install some pre-dependencies
apt-get update
apt-get upgrade
apt-get install ${DPKG_PRE_DEPENDS}

# Release the apt monster!
apt-get update
apt-get upgrade
apt-get install ${DPKG_DEPENDS} ${PIP_DPKG_BUILD_DEPENDS}

# Get pip from upstream because is lighter
py_download_execute https://bootstrap.pypa.io/get-pip.py

# Install python dependencies
pip install ${PIP_OPTS} ${PIP_DEPENDS}

# Remove build depends for pip and unnecessary packages
apt-get purge ${PIP_DPKG_BUILD_DEPENDS} ${DPKG_UNNECESSARY}
apt-get autoremove

# Final cleaning
find /tmp -type f -print0 | xargs -0r rm -rf
find /var/tmp -type f -print0 | xargs -0r rm -rf
find /var/log -type f -print0 | xargs -0r rm -rf
find /var/lib/apt/lists -type f -print0 | xargs -0r rm -rf
find /usr/local/lib/python2.7/dist-packages/github/tests -type f -print0 | xargs -0r rm -rf
