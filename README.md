### Remote Desktop

The main use case for this container is development in C and C++

`docker run docker run --shm-size=1024m --privileged -p 6080:6080 -e VNCPASS=mypwd zinnionlcc/zinnion-desktop-dev`

* VNC is protected by a unique random password for each session
* Desktop runs in a standard user account instead of the root account
* Supports dynamic resizing of the desktop and 24-bit true color
* Supports Ubuntu LTS releases 18.04
* Clion - `2019.3.4`
* g++/gcc `8`
* Vscode - `latest`
* Chromium - `latest`
* Cmake - `3.16.4`

### Cavents

If you open some graphic/work intensive websites in the Docker container (especially with high resolutions e.g. 1920x1080) it can happen that Chrome crashes without any specific reason. The problem there is the too small /dev/shm size in the container, the work around is using `--shm-size`
