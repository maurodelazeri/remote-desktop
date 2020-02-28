### Remote Desktop

The main use case for this container is development in C and C++

### Image
`docker run docker run --shm-size=1024m --privileged -p 6080:6080 -e VNCPASS=mypwd zinnionlcc/zinnion-desktop-dev`

### What this container comes with
* VNC is protected by a unique random password for each session
* Desktop runs in a standard user account instead of the root account
* Supports dynamic resizing of the desktop and 24-bit true color
* Supports Ubuntu LTS releases 18.04
* Clion - `2019.3.4`
* g++/gcc `8`
* Vscode - `latest`
* Chromium - `latest`
* Cmake - `3.16.4`
* Openssl - `1.1.1d`
* Python3

### Cavents

If you open some graphic/work intensive websites in the Docker container (especially with high resolutions e.g. 1920x1080) it can happen that Chrome crashes without any specific reason. The problem there is the too small /dev/shm size in the container, the work around is using `--shm-size`

### Proxy pass

You ideally want to add ssh and protect this session, you can do this with nginx using a vhost as follows

* Restricting Access with HTTP Basic Authentication
    ```
     echo -n 'mauro:' >> /etc/nginx/.htpasswd
     openssl passwd -apr1 >> /etc/nginx/.htpasswd
    ```


```
server {
   listen 80;
   server_name xxx.xxx.com;
   add_header Strict-Transport-Security max-age=2592000;
   rewrite ^ https://$server_name$request_uri? permanent;
}

server {
    listen 443 ssl http2;
    server_name xxx.xxx.com;

    access_log /var/log/nginx/xxx.access.log;
    error_log /var/log/nginx/xxx.error.log;

    ssl on;
    ssl_certificate /opt/ssl/fullchain.pem;
    ssl_certificate_key /opt/ssl/privkey.pem;
    ssl_session_timeout 5m;
    ssl_ciphers EECDH+CHACHA20:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;
    ssl_protocols TLSv1.2;
    ssl_prefer_server_ciphers on;

location / {
    auth_basic "Restricted Content";
    auth_basic_user_file /etc/nginx/.htpasswd;

    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_pass http://127.0.0.1:6080/;
    }
}
```
