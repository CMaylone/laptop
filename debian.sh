#!/bin/sh

# Make sure the script is ran as root for it work properly
if [ "$(id -u)" != "0" ]; then
	echo "Sorry, this script must be ran as root."
	exit 1
fi

install() {
	apt-get install $1 -y
	
	push_install_status $1 true
}

push_install_status() {
	PROGRAM=$1
	STATUS=$2
	
	if [ $STATUS = true ] ; then
		STATUS_TEXT="[\xE2\x9C\x93] $PROGRAM"
	elif [ $STATUS = false ] ; then
		STATUS_TEXT="[\xE2\x9C\x95] $PROGRAM"
	else
		STATUS_TEXT="[-] $PROGRAM"
	fi
	
	INSTALL_STATUS+=("$STATUS_TEXT")
}

print_install_status() {
	for ((i = 0; i < ${#INSTALL_STATUS[@]}; i++))
	do
		echo -e "${INSTALL_STATUS[$i]}"
	done
}

install_visual_studio_code() {
	# Add ubuntu make repo
	add-apt-repository ppa:ubuntu-desktop/ubuntu-make -y
	
	# Update package list
	apt-get -qq update
	
	install ubuntu-make
	
	umake web visual-studio-code

	push_install_status "vscode" true
}

install_chrome() {
	apt-get install libxss1 libappindicator1 libindicator7 -y
	wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
	dpkg -i google-chrome*.deb

	push_install_status "chrome" true
}

install_node() {
	# Name of the set-up script from nodesouce repo. These can be found here https://github.com/nodesource/distributions/tree/master/deb
	NODESOURCE_SETUP_SCRIPT="setup_4.x"
	wget "https://deb.nodesource.com/$NODESOURCE_SETUP_SCRIPT" | sudo -E bash -
	install nodejs
	
	sudo ln -s `which nodejs` /usr/bin/node

	# Install nodejs build essentails
	install build-essential
}

install_font_inconsolata() {
	apt-get install fonts-inconsolata -y
	
	if [ $? -ne 0 ] ; then
		push_install_status "Font:inconsolata" false
		return 1
	fi
	
	# Regenerate the font cache
	fc-cache -fv

	push_install_status "Font:inconsolata" true
}

setup_git() {
	echo -e "Would you like to configure your git global name and email? [y/n]: "
	read SETUP_GIT
	case $SETUP_GIT in
    		[yY][eE][sS]|[yY]) 
			echo -n "Enter global git name and press [ENTER]: "
			read NAME
			echo -n "Enter global git email and press [ENTER]: "
			read EMAIL

			echo "Setting up git with $USERNAME and $EMAIL"
			sudo -u $SUDO_USER git config --global user.name $NAME
			sudo -u $SUDO_USER git config --global user.email $EMAIL
			push_install_status "git configured" true
			;;
	    	*)
			echo -e "Skipping git setup"
			push_install_status "git configured" "unknown"
			;;
	esac
}

setup_ssh() {
	echo -e "Would you like to set-up an SSH key? [y/n]: "
	read SETUP_SSH
	case $SETUP_SSH in
    		[yY][eE][sS]|[yY]) 
			echo -n "Enter email to use as label for new SSH key: "
			read EMAIL
			
			# Run ssh-keygen as current user
			sudo -u $SUDO_USER ssh-keygen -t rsa -b 4096 -C $EMAIL
			push_install_status "ssh configured" true
			;;
	    	*)
			echo -e "Skipping SSH key setup"
			push_install_status "ssh configured" "unknown"
			;;
	esac
}

# Get latest packages before installing new software
apt-get -qq update

install git
install terminator
install_visual_studio_code
install_chrome
install_font_inconsolata
install_node

setup_git
setup_ssh
setup_terminator


echo -e "Programs installed:"
print_install_status

# Shit to install
# install vscode workspace settings
# node, npm, nvm?? - update bash.rc with nvm information
# inconsolata font


# set-up ssh key
