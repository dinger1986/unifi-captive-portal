# UniFi Captive Portal

A [UniFi](https://www.ubnt.com) external captive portal which captures email
addresses and saves them to a csv file, plan will be to email automatically on a set schedule. 
Header image will also be added and will be able to be changed.

## Running

There are two important directories that need to be on disk in order for this
program to run: `assets` and `templates`. Assets holds CSS/JS/IMG assets.
Templates holds the various HTML templates.

If you would like to add custom elements (such as a header image) feel free.
The CSS library used is [Semantic UI](https://semantic-ui.com) so refer to their
documentation if you would like to modify the look.

See the configuration section below for more information regarding the config
file. You will need to specify its location along with the assets and
templates directories.

Also, due to a limitation in the UniFi controller software, external portals
must run on port 80. 

## Installation

Built and tested on Ubuntu 20.04 and Debian 11

```
wget https://raw.githubusercontent.com/dinger1986/unifi-captive-portal/master/install.sh
chmod +x install.sh
./install.sh
```
