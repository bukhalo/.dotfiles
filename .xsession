#!/bin/sh -x

. ~/.secrets.local

cleanup() {
	echo "cleaning up"
	pkill ssh-agent-card-prompt dbus-daemon redshift picom
	rm -f ~/.Xauthority
	rm -rf ~/.local/share/Trash
}
trap cleanup INT TERM QUIT

if [ X`uname -s` = X"Linux" ]; then
	ENVIRONMENT="`cat /sys/devices/virtual/dmi/id/sys_vendor` `cat /sys/devices/virtual/dmi/id/product_name`"
else
	ENVIRONMENT="`sysctl -n hw.vendor` `sysctl -n hw.product`"
fi

# Detect custom PC
if [ "$ENVIRONMENT" == "To Be Filled By O.E.M. To Be Filled By O.E.M." ]; then
	ENVIRONMENT="`cat /sys/devices/virtual/dmi/id/board_vendor` `cat /sys/devices/virtual/dmi/id/board_name`"
fi

export LANG=en_US.UTF-8

# better two-finger touchpad scrolling
export MOZ_USE_XINPUT2=1
# opengl acceleration
export MOZ_ACCELERATED=1
# force webrender to enable
export MOZ_WEBRENDER=1

# to allow style changes with qt5ct
export QT_QPA_PLATFORMTHEME="qt5ct"

SCREEN_WIDTH=`xrandr 2>&1 | grep "Screen 0: minimum" | sed -e 's/.*, current //' -e 's/ x.*//'`
if [ "${SCREEN_WIDTH}" -ge 1920 ]; then
	echo "using HIDPI"
	export HIDPI=1
	export GDK_SCALE=1.5
	export QT_SCALE_FACTOR=1.5
fi

if [ "$HIDPI" = "1" ]; then
	xrdb -DHIDPI=1 -DHOME=$HOME < ~/.Xdefaults
else
	xrdb -DHOME=$HOME < ~/.Xdefaults
fi

xsetroot -cursor_name left_ptr

xmodmap ~/.xmodmap
xbindkeys
xset b 0 0 0
xset r rate 350 35

# disable built-in saver, because xidle will handle it
xset s off
# disable dpms, because slock will handle it
xset dpms 0 0 0

# ~/bin/music called from lock needs DBUS_SESSION_BUS_ADDRESS
eval `dbus-launch --sh-syntax`

# ~/bin/lock does some protections and runs slock
xidle -timeout 900 -ne -program ~/bin/lock &

xbanish &

WM=dwm

hsetroot -solid "#a3ccbd"
picom -b

case $ENVIRONMENT in
"HONOR HGE-WX6")
	xdimmer &
	# turn off the touchscreen
	xinput disable /dev/wsmouse2
	# touchpad tuning
	xinput set-prop /dev/wsmouse0 "Device Accel Velocity Scaling" 1
	;;

"ASRock A320M-HDV R4.0")
	echo "Xft.dpi: 173" | xrdb -merge
	# export GDK_DPI_SCALE=1.5
	export QT_SCALE_FACTOR=1.7
	export QT_FONT_DPI=96
	WM=awesome
	;;

*)
	echo "running in unknown environment \"${ENVIRONMENT}\""
	;;
esac

# run after any icc profile loading
redshift -l $LOCATION_COORDS -t 6500:3500 -m randr &

if [ -f ~/.xsession.local ]; then
	. ~/.xsession.local
fi

if [ "$WM" == "dwm" ]; then
	. ~/bin/dwm-status
fi

$WM

setxkbmap -layout us,ru -option grp:caps_toggle

cleanup
