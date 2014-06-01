Web Interface for RetroShare (nogui)

RetroFlux provides
- Search Files
- Download (Start, Pause, Restart and Stop)
- RSCollection (Read Collection and download files)
- Peers (Add and Remove)
- Chatlobbies (Join and Leave)
- see Status

Installation guidelines see Wiki http://sourceforge.net/p/retroflux/wiki/Install/



Install

1) Raspbian or Debian or Ubuntu Base System already installed
2) install RetroShare-nogui "sudo apt-get install retroshare-nogui"
from https://launchpad.net/~csoler-users/+archive/retroshare-snapshots/
or http://sourceforge.net/projects/pishare/
or http://sourceforge.net/projects/retroshare/
3) generate the ssh host key "ssh-keygen -t rsa -f rs_ssh_host_rsa_key"
4) generate the retroshare ssh password hash "RetroShare-nogui -G"
5) generate a new location (or new key) with the normal RetroShare-GUI version on another computer, add some friends, close it and copy (with scp) the config folder to ~/.retroshare
6) start the whole process with "RetroShare-nogui -X -S 7022 -L user -P 'hash generated above'" and enter your PGP password if asked
7) install Webserver with CGI Support (Lighttpd or Apache) "sudo apt-get install lighttpd"
8) enable cgi module "lighttpd-enable-mod cgi"
9) edit cgi config file "vi /etc/lighttpd/conf-enabled/10-cgi.conf"
10) put this line "alias.url += ( "/cgi-bin/" => "/usr/lib/cgi-bin/" )"
after "server.modules += ( "mod_cgi" )"
11) restart lighttpd "/etc/init.d/lighttpd force-reload"
12) download RetroFlux http://sourceforge.net/projects/retroflux/files/retroflux-0.6.1/retroflux-0.6.1.deb/download
13) install all depends "apt-get install
libnumber-bytes-human-perl libnet-ssh2-perl libparse-recdescent-perl libfilesys-df-perl libhtml-template-perl libhtml-template-expr-perl liburi-perl libclass-accessor-perl libxml-libxml-perl libjson-perl libcgi-session-perl"
14) install RetroFlux "dpkg -i retroflux-0.6.1.deb"
15) add "username", "password" (no hash) and "download folder" to configfile "vi /usr/lib/cgi-bin/retroFlux/config.cgi"
16) start your browser and go to http://hostip/retroFlux/
Deinstall

1) sudo apt-get remove retroflux

Have Fun

