#!/bin/bash
#set -x
# ==================================
# OpenVPN Manager
# ==================================

#Colors
ok="[\e[1;32m OK \e[0;39m]"
info="[\e[1;36mINFO\e[0;39m]"
warn="[\e[1;33mWARN\e[0;39m]"
fail="[\e[1;31mFAIL\e[0;39m]"
warning="\e[1;31mWARNING!\e[0;39m"
white="\e[0;39m"
yellow="\e[1;33m"
red="\e[1;31m"
green="\e[1;32m"
#Other settings...
rootdir=$(dirname $(readlink -f $0))

# ==================================
# Vars
# ==================================

#working dir
dir=/etc/openvpn

# ==================================
# Functions
# ==================================

ask_yn(){
	read -p "Do you want to continue [y/N]? " -t 10 yn || { if [ "$?" -gt 128 ];then return 180; fi; }
	yn=$(echo $yn | awk '{print tolower($0)}')
	if [ "$yn" != "y" ];then
		echo Abort.
		return 18
	fi
}

#error messages
get_error(){
	case $1 in
		0)                  # no error
			echo -e "Error : code run perfectly ! ($1)";;
		18)                 # error from user
			echo -e "I/O error with user interface ! ($1)";;
		180)                # error when prompt got a timeout
			echo -e "User fall asleep on keyboarddddddddddddddddddddddddddddddddddddddddddddddddddddddddd ($1)";;
		181)                # 
			echo -e "What part of ONE ARGUMENTS don't you understand ? ($1)";;
		182)                # Two args required
			echo -e "What part of TWO ARGUMENTS don't you understand ? ($1)";;
		183)                # Three args required
			echo -e "This one need THREE ARGUMENTS ! ($1)";;
		42)                 # Can't be raised !
			echo -e "How the fuck this is happening... ($1)";;
		*)                  # non-handled error (atm)
			echo -e "Unknown error ! ($1)";;
	esac
}

########################################
## OpenVPN Manager Specific functions ##
########################################

ovpn_start(){
	if ps ax | grep openvpn | grep -v grep | grep -v tail;then
		echo -e "$info OpenVPN daemon is already running !"
	else
		# load TUN/TAP kernel module
		modprobe tun

		# enable IP forwarding
		echo 1 > /proc/sys/net/ipv4/ip_forward

		/usr/sbin/openvpn --cd $dir --daemon --writepid $dir/.ovpn.pid --config server.conf || get_error $?
		echo -e "$ok Done."
	fi
}

ovpn_stop(){
	local pid=$(cat $dir/.ovpn.pid)
	kill -15 $pid
	count=0
	until [ $count -gt 30 ];do
		if [ "$(ps $pid | grep -v PID)" ];then
			echo -n "."
			sleep 1
			((count++))
		else
			count=999
		fi
	done
	if [ $count = 999 ];then
		rm $dir/.ovpn.pid
		echo -e "$ok Done."
	else
		echo -e "$warn OpenVPN daemon is still running !"
	fi
}

#restart openvpn
ovpn_restart(){
	ovpn_stop
	ovpn_start
}

#################################
## easy-rsa Specific functions ##
#################################
# made for easyrsa 3

#init pki ca and co
ersa_init(){
	cd $dir/easy-rsa

	./easyrsa init-pki

	./easyrsa build-ca

	./easyrsa gen-dh

}

ersa_create(){
	cd $dir/easy-rsa
	case $2 in
		client)
			./easyrsa build-client-full $3 $4 || get_error $?;;
		server)
			./easyrsa build-server-full $3 nopass || get_error $?;;
		*)
			return 182;;
	esac
}

# # #

get_help(){
echo -e '    Commands :'
echo
}

# GO!
case $1 in
	start)
		ovpn_start "$@" || get_error $?;;
	stop)
		ovpn_stop "$@" || get_error $?;;
	restart)
		ovpn_restart "$@" || get_error $?;;
	create)
		ersa_create "$@" || get_error $?;;
	help|?)
		get_help;;
	*)
		echo -e "Usage: $0 {start|stop|restart}"
	exit 18;;
esac
exit 0
