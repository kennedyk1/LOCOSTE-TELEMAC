﻿# **TELEMAC LOCOSTE INSTALL**

tested on:
 - [x] Ubuntu 20.04 LTS (*64 bits*)

**Use the follow instructions to install TELEMAC-v7p0r0.**

To download, use git:
> git clone https://github.com/kennedyk1/LOCOSTE-TELEMAC.git

> cd LOCOSTE-TELEMAC

> source install_telemac

The softwares will be installed on **/usr/**
- /usr/TELEMAC-v7p0r0
- /usr/hdf5
- /usr/metis-5.1.0
- /usr/parmetis
- /usr/scotch

A folder **TELEMAC-v7p0r0** will be created on **/home/\<username\>/** with symbolic links.

The **/home/\<username\>/.bashrc** will be updated to easy commands.

#
**HOW TO TEST IF IT WORKS?**
#

Just copy and paste the command bellow on terminal:
> telemac2d.py /usr/TELEMAC-v7p0r0/examples/telemac2d/gouttedo/t2d_gouttedo.cas --ncsize=4

The message will appear in terminal: **My work is done**

**--> Based on the official guide:** http://wiki.opentelemac.org/doku.php?id=installation_on_linux


#
**HOW TO INSTALL AND RUN TELEMAC ON WINDOWS 10?**
#

Please read files inside "**Tutorial WLS2 no Windows 10**" folder.
