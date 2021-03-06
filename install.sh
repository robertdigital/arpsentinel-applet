#!/bin/sh
# This file is part of ARP Sentinel.
#
#    ARP Sentinel is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

APP_HOME="arpsentinel-applet"
APP_UUID="arpsentinel@$APP_HOME.github.io"
CINNAMON_APPLETS="$HOME/.local/share/cinnamon/applets/"
DBUS_SERVICE="[D-BUS Service]\nName=org.arpsentinel\nExec=\"$HOME/.$APP_HOME/bin/arpalert-service.py\"\nUser=arpalert"

error(){
  [ -z "$1" ] && echo " KO" || echo "\n[-] ERROR: $1"
  exit
}

check_arpalert(){
  cmd=$(sudo which arpalert)
  if [ "$?" != 0 ]
  then
      echo "[!!] You must install arpalert first: sudo apt-get install arpalert || sudo yum install arpalert"
      echo
      exit 1
  fi
}

check_arpalert

mkdir -p ~/.$APP_HOME/bin/ 2>/dev/null
touch ~/.$APP_HOME/maclist.allow ~/.$APP_HOME/maclist.deny ~/.$APP_HOME/maclist.trusted
/bin/cp ./arpalert-service.py ./arpalert.sh ~/.$APP_HOME/bin/

#chown arpalert ~/.$APP_HOME/maclist.allow ~/.$APP_HOME/maclist.deny
#[ "$?" != "0" ] || error "You must install arpalert: sudo apt-get install arpalert, sudo dnf install arpalert, etc"

mkdir -p $CINNAMON_APPLETS 2>/dev/null
out=$(/bin/cp -a $APP_UUID/ $CINNAMON_APPLETS)
[ "$?" = "0" ] && echo " OK" || error

echo -n "[+] Enable ARPSentinel system service: "
#echo -e $DBUS_SERVICE
out=$(/bin/echo -e $DBUS_SERVICE > arpsentinel.service.temp; sudo /bin/cp arpsentinel.service.temp /usr/share/dbus-1/system-services/org.arpsentinel.service)
if [ "$?" = "0" ]
then
    rm -f arpsentinel.service.temp
else
    echo " Error generating the DBUS service"
fi
out=$(sudo /bin/cp ./arpsentinel.conf /etc/dbus-1/system.d/)
[ "$?" = "0" ] && echo " OK" || error

echo "[+] Now modify the following options of /etc/arpalert/arpalert.conf:"
echo "    maclist file = "$HOME/.$APP_HOME/maclist.allow""
echo "    maclist alert file = "$HOME/.$APP_HOME/maclist.deny""
echo "    action on detect = "$HOME/.$APP_HOME/bin/arpalert.sh""
#echo "    maclist leases file = "$HOME/$APP_HOME/arpalert.leases""

sleep 2
# check if /etc/sudoers.d/ exists
# if [ -d '/etc/sudoers.d' ] ...
echo "[+] And add this line to /etc/sudoers to effectively block offenders:"
echo "    user host = (root) NOPASSWD: $HOME/.$APP_HOME/block_mac.sh"

sleep 2

sudo service arpalert restart || sudo /etc/init.d/arpalert restart

echo "DONE"
