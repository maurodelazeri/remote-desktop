# Builds a base Docker image for Ubuntu with X Windows and VNC support.
FROM ubuntu:18.04
LABEL maintainer Mauro Delazeri <maurodelazeri@gmail.com>

ARG DOCKER_LANG=en_US
ARG DOCKER_TIMEZONE=America/New_York

ENV LANG=$DOCKER_LANG.UTF-8 \
    LANGUAGE=$DOCKER_LANG:UTF-8 \
    LC_ALL=$DOCKER_LANG.UTF-8

WORKDIR /tmp

ARG DEBIAN_FRONTEND=noninteractive

# Install some required system tools and packages for X Windows and ssh
# Also remove the message regarding unminimize
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        apt-utils \
        apt-file \
        locales \
        language-pack-en && \
    locale-gen $LANG && \
    dpkg-reconfigure -f noninteractive locales && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
	zlib1g-dev \
	libcurl4 \
	curl \
 	wget \
	git \
	build-essential \
	dnsutils \
        curl \
        less \
        vim \
        psmisc \
        runit \
        apt-transport-https ca-certificates \
        software-properties-common \
        man \
        sudo \
        rsync \
        bsdtar \
        net-tools \
        gpg-agent \
        inetutils-ping \
        csh \
        tcsh \
        zsh \
        build-essential \
        libssl-dev \
        git \
        dos2unix \
        dbus-x11 \
        \
        openssh-server \
        python \
        python3 \
        python3-pip \
        python3-distutils \
        python3-tk \
        python3-dbus \
        \
        xserver-xorg-video-dummy \
        lxde \
        x11-xserver-utils \
        xterm \
        gnome-themes-standard \
        gtk2-engines-pixbuf \
        gtk2-engines-murrine \
        libcanberra-gtk-module libcanberra-gtk3-module \
        ttf-ubuntu-font-family \
        xfonts-base xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic \
        libopengl0 mesa-utils libglu1-mesa libgl1-mesa-dri libjpeg8 libjpeg62 \
        xauth \
        x11vnc \
        xpdf && \
    chmod 755 /usr/local/share/zsh/site-functions && \
    apt-get -y autoremove && \
    ssh-keygen -A && \
    ln -s -f /lib64/ld-linux-x86-64.so.2 /lib64/ld-lsb-x86-64.so && \
    perl -p -i -e 's/#?X11Forwarding\s+\w+/X11Forwarding yes/g; \
        s/#?X11UseLocalhost\s+\w+/X11UseLocalhost no/g; \
        s/#?PasswordAuthentication\s+\w+/PasswordAuthentication no/g; \
        s/#?PermitEmptyPasswords\s+\w+/PermitEmptyPasswords no/g' \
        /etc/ssh/sshd_config && \
    rm -f /etc/update-motd.d/??-unminimize && \
    rm -f /etc/xdg/autostart/lxpolkit.desktop && \
    chmod a-x /usr/bin/lxpolkit && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#RUN apt-get update; apt-get install -y zlib1g-dev curl

# Upgrade openssl
RUN cd /usr/local/src/ && wget https://www.openssl.org/source/openssl-1.1.1d.tar.gz && tar -xf openssl-1.1.1d.tar.gz && \
	cd openssl-1.1.1d && ./config --prefix=/usr/local/ssl --openssldir=/usr/local/ssl shared zlib && make && make install && \
	cd .. && rm openssl-1.1.1d.tar.gz
 	
RUN cd /etc/ld.so.conf.d/ && echo "/usr/local/ssl/lib" >  openssl-1.1.1b.conf
RUN mv /usr/bin/c_rehash /usr/bin/c_rehash.BEKUP
RUN mv /usr/bin/openssl /usr/bin/openssl.BEKUP
RUN ln -s /usr/local/ssl/bin/openssl /usr/bin/openssl
RUN echo "PATH=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/local/ssl/bin\"" > /etc/environment

RUN echo "export OPENSSL_ROOT_DIR=/usr/local/src/openssl-1.1.1d" >> /etc/profile
RUN echo "export OPENSSL_LIBRARIES=/usr/local/src/openssl-1.1.1d" >> /etc/profile
RUN echo "export OPENSSL_CRYPTO_LIBRARY=/usr/local/src/openssl-1.1.1d" >> /etc/profile

#RUN apt-get update && apt-get install -y libcurl3 curl libcurl-openssl1.0-dev
RUN apt-get update && apt-get install -y libcurl4 curl

# Install websokify and noVNC
RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python2 get-pip.py && \
    pip2 install --no-cache-dir \
        setuptools && \
    pip2 install -U https://github.com/novnc/websockify/archive/60acf3c.tar.gz && \
    mkdir /usr/local/noVNC && \
    curl -s -L https://github.com/x11vnc/noVNC/archive/master.tar.gz | \
         bsdtar zxf - -C /usr/local/noVNC --strip-components 1 && \
    rm -rf /tmp/* /var/tmp/*

# Install x11vnc from source
# Install X-related to compile x11vnc from source code.
# https://bugs.launchpad.net/ubuntu/+source/x11vnc/+bug/1686084
# Also, fix issue with Shift-Tab not working
# https://askubuntu.com/questions/839842/vnc-pressing-shift-tab-tab-only
RUN apt-get update && \
    apt-get install -y libxtst-dev libssl-dev libjpeg-dev && \
    \
    mkdir -p /tmp/x11vnc-0.9.14 && \
    curl -s -L http://x11vnc.sourceforge.net/dev/x11vnc-0.9.14-dev.tar.gz | \
        bsdtar zxf - -C /tmp/x11vnc-0.9.14 --strip-components 1 && \
    cd /tmp/x11vnc-0.9.14 && \
    ./configure --prefix=/usr/local CFLAGS='-O2 -fno-stack-protector -Wall' && \
    make && \
    make install && \
    perl -e 's/,\s*ISO_Left_Tab//g' -p -i /usr/share/X11/xkb/symbols/pc && \
    apt-get -y remove libxtst-dev libssl-dev libjpeg-dev && \
    apt-get -y autoremove && \
    ldconfig && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

########################################################
# Customization for user and location
########################################################
# Set up user so that we do not run as root in DOCKER
ENV DOCKER_USER=ubuntu \
    DOCKER_UID=9999 \
    DOCKER_GID=9999 \
    DOCKER_SHELL=/bin/zsh

ENV DOCKER_GROUP=$DOCKER_USER \
    DOCKER_HOME=/home/$DOCKER_USER \
    SHELL=$DOCKER_SHELL

# Change the default timezone to $DOCKER_TIMEZONE
# Run ldconfig so that /usr/local/lib etc. are in the default
# search path for dynamic linker
RUN groupadd -g $DOCKER_GID $DOCKER_GROUP && \
    useradd -m -u $DOCKER_UID -g $DOCKER_GID -s $DOCKER_SHELL -G sudo $DOCKER_USER && \
    echo "$DOCKER_USER:"`openssl rand -base64 12` | chpasswd && \
    echo "$DOCKER_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo "$DOCKER_TIMEZONE" > /etc/timezone && \
    ln -s -f /usr/share/zoneinfo/$DOCKER_TIMEZONE /etc/localtime

ADD image/etc /etc
ADD image/usr /usr
ADD image/sbin /sbin
ADD image/home $DOCKER_HOME

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
RUN add-apt-repository ppa:ubuntu-toolchain-r/test && apt-get update && apt-get install -y gcc-8 g++-8 openjdk-11-jdk yarn apt-transport-https chromium-browser

RUN rm /usr/bin/gcc
RUN rm /usr/bin/g++
RUN ln -s /usr/bin/gcc-8 /usr/bin/gcc
RUN ln -s /usr/bin/g++-8 /usr/bin/g++

RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
RUN install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/
RUN sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
RUN apt-get update && apt-get install code -y 

RUN cd $DOCKER_HOME && wget https://download-cf.jetbrains.com/cpp/CLion-2019.3.4.tar.gz --no-check-certificate && tar -zxvf CLion-2019.3.4.tar.gz && rm CLion-2019.3.4.tar.gz

ENV OPENSSL_ROOT_DIR=/usr/local/src/openssl-1.1.1d
ENV OPENSSL_LIBRARIES=/usr/local/src/openssl-1.1.1d
ENV OPENSSL_CRYPTO_LIBRARY=/usr/local/src/openssl-1.1.1d

RUN cd $DOCKER_HOME && wget https://github.com/Kitware/CMake/releases/download/v3.16.4/cmake-3.16.4.tar.gz --no-check-certificate && \
	tar -zxvf cmake-3.16.4.tar.gz && cd cmake-3.16.4 && ./bootstrap && make && make install && cd .. && rm -rf cmake*

RUN touch $DOCKER_HOME/.sudo_as_admin_successful && \
    mkdir -p $DOCKER_HOME/shared && \
    mkdir -p $DOCKER_HOME/.ssh && \
    mkdir -p $DOCKER_HOME/.log && touch $DOCKER_HOME/.log/vnc.log && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME

WORKDIR $DOCKER_HOME

ENV DOCKER_CMD=start_vnc

USER root
ENTRYPOINT ["/sbin/my_init", "--quiet", "--", "/sbin/setuser", "ubuntu"]
CMD ["$DOCKER_CMD"]
