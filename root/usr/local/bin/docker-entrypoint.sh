#!/usr/bin/env bash

. /etc/profile
. /usr/local/bin/docker-entrypoint-functions.sh

MYUSER="${APPUSER}"
MYUID="${APPUID}"
MYGID="${APPGID}"

AutoUpgrade
ConfigureUser

if [ "$1" == 'plex' ]; then
  mkdir -p /config
  chown -R "${MYUSER}":"${MYUSER}" /config
  chmod -R 0750 /config
  mkdir -p /transcode
  chown -R "${MYUSER}":"${MYUSER}" /transcode
  chmod -R 0750 /transcode
  cd /config
  rm -rf /var/run/dbus
  mkdir -p /var/run/dbus
  DockLog "Starting app: dbus-daemon"
  exec dbus-daemon --system --nofork &
  until [ -e /var/run/dbus/system_bus_socket ]; do
    DockLog  "dbus-daemon is not running on hosting server..."
    sleep 1s
  done
  cat <<EOF > /tmp/plex-env
PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR=/var/lib/plexmediaserver/Library/Application Support
PLEX_MEDIA_SERVER_HOME=/usr/lib/plexmediaserver
PLEX_MEDIA_SERVER_MAX_PLUGIN_PROCS=6
PLEX_MEDIA_SERVER_TMPDIR=/tmp
LC_ALL=en_US.UTF-8
LANG=en_US.UTF-8
PLEX_MEDIA_SERVER_INFO_VENDOR=$(grep ^NAME= /etc/os-release | awk -F= "{print \\$2}" | tr -d \\" )
PLEX_MEDIA_SERVER_INFO_DEVICE=PC
PLEX_MEDIA_SERVER_INFO_MODEL=$(uname -m)
PLEX_MEDIA_SERVER_INFO_PLATFORM_VERSION=$(grep ^VERSION= /etc/os-release | awk -F= "{print \\$2}" | tr -d \\" )
LD_LIBRARY_PATH=/usr/lib/plexmediaserver/lib
EOF
  PrepareEnvironment /tmp/plex-env
  . /etc/profile
  DockLog "Starting app: avahi-daemon"
  exec avahi-daemon --no-chroot &
  DockLog "Starting app: ${1}"
  exec su-exec "${MYUSER}" /usr/lib/plexmediaserver/Plex\ Media\ Server
else
  DockLog "Starting app: ${@}"
  exec "$@"
fi