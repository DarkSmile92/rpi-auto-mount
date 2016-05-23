#!/bin/sh
# Script to modify /etc/fstab file to automatically mount external hard drives during boot.
# Copyright (C) 2016 Robin Kretzschmar - All Rights Reserved
# Permission to copy and modify is granted under the GNU General Public License.
# Last revised 25.05.2016
#
## Usage: sudo bash rpi-auto-mount.sh
##
## Options:
##   -h, --help    Display this message.
##

function init {
	RED='\033[0;31m'
	GREEN='\033[0;32m'
	CYAN='\033[0;36m'
	NC='\033[0m' # No Color
}

function replace_fstab {
	echo -n "UUID=$m_uuid" >> /etc/fstab 	# UUID of device
	echo -e -n "\t" >> /etc/fstab			# TAB
	echo -n "$m_dest" >> /etc/fstab			# Mount destination path
	echo -e -n "\t" >> /etc/fstab			# TAB
	#echo -n "$m_type" >> /etc/fstab		# Filesystem type
	echo -n "auto" >> /etc/fstab			# Automatically choose filesystem type
	echo -e -n "\t" >> /etc/fstab			# TAB
	echo -n "nofail,uid=1001,gid=1001,errors=remount-ro" >> /etc/fstab # USER ID, GROUP ID etc.
	echo -e -n "\t" >> /etc/fstab			# TAB
	echo -n "0" >> /etc/fstab				
	echo -e -n "\t" >> /etc/fstab			# TAB
	echo "1" >> /etc/fstab				
	
	printf "${GREEN}'/etc/fstab' patched!${NC}\n"
}

function set_type {
	echo "Setting up '$1' to be mounted on startup ..."
	echo "Type: $(sudo blkid -o value -s TYPE $1)"
	
	m_type=$(sudo blkid -o value -s TYPE $1)
	
	#case $(sudo blkid -o value -s TYPE $1) in
	#	"ntfs" ) echo "preparing NTFS";;
	#	* ) echo "Everything else";;
	#esac
	echo "Filesystem type: $m_type"
	set_mount_path
}

function set_mount_path {
	printf "${CYAN}Enter mount destination: ${NC}\n"
	read dest
	if [ $dest != "" ] && [ -d $dest ]; then
		echo "Path ok..."
		m_dest=$dest
		replace_fstab
	else
		printf "${RED}Path '$dest' does not exist!${NC}\n"
	fi
}

function ask_sure {
	options=("Yes")
	title="Selected '$1'"
	prompt="Automount '$1' ?"

	echo "$title"
	PS3="$prompt "
	select opt in "${options[@]}" "Quit"; do 

		case "$REPLY" in

		1 ) echo "Proceeding..."; m_device = $1;set_type $1;break;;

		$(( ${#options[@]}+1 )) ) echo "Goodbye!"; break;;
		*) echo "Invalid option. Try another one.";continue;;

		esac

	done
}

createmenu ()
{
	#echo "Size of array: $#"
	#echo "$@"
	title="Devices"
	prompt="Pick a device ($(($#+1)) to exit):"

	echo "$title"
	PS3="$prompt "
  
	select option; do # in "$@" is the default
		if [ "$REPLY" -gt "$#" ];
		then
			echo "Goodbye!"
			break;
		elif [ 1 -le "$REPLY" ] && [ "$REPLY" -le $(($#-1)) ];
		then
			#echo "You selected $option which is option $REPLY"
			m_uuid=$(echo $option | sed -e "s/^.*\((\)\(.*\)\()\).*$/\2/")
			#echo "Selected UUID: $m_uuid"
			ask_sure $option
			break;
		else
			printf "${RED}Incorrect Input: Select a number 1-$#${NC}\n"
		fi
	done
}

function select_device {
	devives_list=

	for DEVICE in $(sudo blkid -o device); do
		LABEL=$(sudo blkid -o value -s LABEL $DEVICE)
		UUID=$(sudo blkid -o value -s UUID $DEVICE)
		#echo "$DEVICE = $LABEL ($UUID)"
		devices_list[i]="$DEVICE = $LABEL ($UUID)"
		let i++
	done

	createmenu "${devices_list[@]}"
}

init
select_device
