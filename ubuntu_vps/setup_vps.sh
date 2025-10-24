#!/bin/bash

welcome="
VPS SETUP
Ubuntu 22.04

~/dxtstd
"

### WHEN $PREFIX IS UNDEFINED
if ! [ $PREFIX ]
then
    PREFIX='/usr'
fi
### WHEN $TMPDIR IS UNDEFINED
if ! [ $TMPDIR ]
then
    TMPDIR='/tmp'
fi

if [ -e "${PREFIX}/bin/figlet" ]
then
    figlet $welcome
else
    echo "\"$welcome\""
    echo
fi

DEVICE_OS=$(uname -o)
DEVICE_ARCH=$(uname -m)
echo "Detected OS: ${DEVICE_OS}"
echo "Detected Arch: ${DEVICE_ARCH}"
echo ""

if [ $UID != 0 ];
then
  echo "you must run this script on root user..."
  exit
fi

### execute setuping VPS

PACKAGE="git ffmpeg sox libsox-fmt-all"
install_package () {
    echo "Update repo list & Upgrade Packages..."
    apt update && apt upgrade -y 

    echo
    echo "Installing \"$PACKAGE\" package... "
    apt install $PACKAGE -y 

    echo
}
install_package

## For NodeJS
URL_NODEJS=""
NODEJS_LINUX() {
    NODEJS_WEB="https://nodejs.org/dist"
    NODEJS_VERSION="v22.21.0"
    NODEJS_ARCH="x64"
    NODEJS_PLATFORM="linux"

    if { [ $DEVICE_ARCH == 'amd64' ] || [ $DEVICE_ARCH == 'x86_64' ]; }
    then
        NODEJS_ARCH='x64'
        else if { [ $DEVICE_ARCH == 'aarch64' ]; }
        then
            NODEJS_ARCH='arm64'
            else if { [ $DEVICE_ARCH == 'aarch32' ] || [ $DEVICE_ARCH == 'armv8l' ] || [ $DEVICE_ARCH == 'armv7l' ]; }
            then
                NODEJS_ARCH='armv7l'
            fi
        fi
    fi
    NODEJS_PACKAGE="node-${NODEJS_VERSION}-${NODEJS_PLATFORM}-${NODEJS_ARCH}.tar.gz"
    URL_NODEJS="${NODEJS_WEB}/${NODEJS_VERSION}/${NODEJS_PACKAGE}"
}


install_nodejs () {
  read -p "Install a NodeJS? [Y/n]: " ANSWER_NJS_INSTALL
  case "$ANSWER_NJS_INSTALL" in
    [Yy][Ee][Ss]|[Yy])
      NODEJS_LINUX
      echo URl NodeJS: "$URL_NODEJS"

      echo 'Downloading NodeJS...'
      wget -O $TMPDIR/nodejs.tar.gz $URL_NODEJS
      echo 'Extract NodeJS...'
      mkdir $TMPDIR/nodejs
      tar xfz $TMPDIR/nodejs.tar.gz -C $TMPDIR/nodejs
      echo "Move File To $PREFIX..."
      cp -rf $TMPDIR/nodejs/*/* $PREFIX
      echo "Remove TMP NodeJS..."
      rm -rf $TMPDIR/node*

      NPM_MODULE="ts-node typescript nodemon pm2 yarn"
      echo "Installing NPM Module $NPM_MODULE (Global)..."
      npm install -g $NPM_MODULE

      echo
    ;;
    [Nn][Oo]|[Nn])
      
    ;;
    *)
      install_nodejs
    ;;
  esac
}
install_nodejs

VSCODE_URL="https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
CHROME_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
ask_install_desktop () {
    read -p "Install a Desktop Environment? [Y/n]: " ANSWER_DE_INSTALL
    case "$ANSWER_DE_INSTALL" in
        [Yy][Ee][Ss]|[Yy])
            echo "Installing Package DE..."
            apt install xfce4 xfce4-goodies tigervnc-standalone-server -y
            
            echo "Fetch Chrome, VSCode..."
            mkdir $TMPDIR/deb-package
            wget -O $TMPDIR/deb-package/VSCODE.deb $VSCODE_URL
            wget -O $TMPDIR/deb-package/CHROME.deb $CHROME_URL
            echo "Installing Chrome, VSCode..."
            apt install $TMPDIR/deb-package/*.deb -y
            rm -rf $TMPDIR/deb-package
            
            echo "Configuring VNC File..."
            for USER_HOME_DIR in /home/*; do
              echo $USER_HOME_DIR
              if [ ! -d $USER_HOME_DIR/.vnc ]
              then
                  mkdir $USER_HOME_DIR/.vnc
              fi
              cp ./xstartup $USER_HOME_DIR/.vnc/xstartup -f
              chmod +x $USER_HOME_DIR/.vnc/xstartup

              USERNAME=`echo $USER_HOME_DIR | sed 's/\/home\///g'`
              chown -R $USERNAME:$USERNAME $USER_HOME_DIR/.vnc/
            done
            
            echo
        ;;
        [Nn][Oo]|[Nn])
            
        ;;
        *)
          ask_install_desktop
        ;;
    esac
}
ask_install_desktop

config_pulseaudio () {
  echo "Configuring pulseaudio..."
  if [ -e "/etc/pulse/default.pa" ];
  then
      cp -f ./default.pa /etc/pulse/default.pa
      
  else
      echo "Pulseaudio not found..."
  fi
}
config_pulseaudio

config_swap () {
  echo "Configuring swap..."
  if [ -e "/swap" ]
  then
    echo "swap already exists"
    swapon /swap
  else
    fallocate -l 8G /swap
    chmod 600 /swap
    mkswap /swap
    swapon /swap

    echo '/swap none swap sw 0 0' | sudo tee -a /etc/fstab
  fi
  

}
