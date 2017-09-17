#!/usr/bin/env bash
set -o errexit

DIR=$(mktemp -d)
trap 'rm -rf "$DIR"' EXIT

# N4IRS 07/26/2017

#################################################
#                                               #
#                                               #
#                                               #
#################################################

# This script will install AllStarLink Asterisk on a existing Debian installation.

apt-get update

# DL AllStar master
wget -qO- https://github.com/AllStarLink/DIAL/archive/master.tar.gz | tar xvz -C $DIR

# install required
$DIR/DIAL-master/scripts/required_libs.sh

# install build_tools
$DIR/DIAL-master/scripts/build_tools.sh

# get AllSter, DAHDI and kernel headers
$DIR/DIAL-master/scripts/get_src.sh

# build DAHDI
$DIR/DIAL-master/scripts/build_dahdi.sh

# patch Asterisk
$DIR/DIAL-master/scripts/patch_asterisk.sh

# Build Asterisk
$DIR/DIAL-master/scripts/build_asterisk.sh

# make /dev/dsp available
# not needed for a hub
# Though it will not hurt anything.
echo snd_pcm_oss >>/etc/modules

# Add asterisk to logrotate
$DIR/DIAL-master/scripts/mk_logrotate_asterisk.sh

# Put user scripts into /usr/local/sbin
cp -rf $DIR/DIAL-master/post_install/* /usr/local/sbin
cp /usr/src/astsrc-1.4.23-pre/allstar/rc.updatenodelist /usr/local/bin/rc.updatenodelist

# Check this out. I think it's done by modified asterisk make file now.
# Could be redundant.

codename=$(lsb_release -cs)
if [[ $codename == 'jessie' ]]; then
  # start update node list on boot via systemd
  cp $DIR/DIAL-master/systemd/updatenodelist.service /lib/systemd/system
  systemctl enable updatenodelist.service
elif [[ $codename == 'wheezy' ]]; then
  # start update node list on boot via init.d
  cp $DIR/DIAL-master/scripts/updatenodelist /etc/init.d
  /usr/sbin/update-rc.d updatenodelist start 50 2 3 4 5 . stop 91 2 3 4 5
fi

# Move this. OK for now
ln -s /usr/local/sbin/check-update.sh /etc/cron.daily/check-update.sh
touch /var/tmp/update.old

touch /etc/asterisk/firsttime

echo "test -e /etc/asterisk/firsttime && /usr/local/sbin/firsttime" >>/root/.bashrc

echo "AllStar Asterisk install Complete."

echo reboot
