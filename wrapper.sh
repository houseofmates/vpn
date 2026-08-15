#!/bin/bash
export QT_QPA_PLATFORM=xcb
export XDG_SESSION_TYPE=x11
exec /home/house/projects/apps-manager/vpn_local/vpn "$@"
