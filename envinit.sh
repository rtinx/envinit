#!/bin/bash
#

NFSROOT=/opt/nfsroot
TFTPROOT=/opt/tftproot

function GetDistroName()
{
    if grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        DISTRO='CentOS'
        PM='yum'
    elif grep -Eqi "Red Hat Enterprise Linux Server" /etc/issue || grep -Eq "Red Hat Enterprise Linux Server" /etc/*-release; then
        DISTRO='RHEL'
        PM='yum'
    elif grep -Eqi "Aliyun" /etc/issue || grep -Eq "Aliyun" /etc/*-release; then
        DISTRO='Aliyun'
        PM='yum'
    elif grep -Eqi "Fedora" /etc/issue || grep -Eq "Fedora" /etc/*-release; then
        DISTRO='Fedora'
        PM='yum'
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        DISTRO='Debian'
        PM='apt'
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        DISTRO='Ubuntu'
        PM='apt'
    elif grep -Eqi "Raspbian" /etc/issue || grep -Eq "Raspbian" /etc/*-release; then
        DISTRO='Raspbian'
        PM='apt'
    else
        DISTRO='unknow'
    fi
}

function usage() 
{
    echo "Usage: envinit.sh"
    echo "       -t TFTP server root folder"
    echo "       -n NFS  server root folder"
    exit 0
}

function ubuntu_tftp_init()
{
	apt-get install tftpd-hpa
	systemctl enable tftpd-hpa
	systemctl restart tftpd-hpa
	
	cp /etc/default/tftpd-hpa /etc/default/tftpd-hpa.ORIGINAL
	
	echo "# /etc/default/tftpd-hpa" > /etc/default/tftpd-hpa
	echo >> /etc/default/tftpd-hpa
	echo "TFTP_USERNAME=\"tftp\"" >> /etc/default/tftpd-hpa
    echo "TFTP_DIRECTORY=\"$TFTPROOT\"" >> /etc/default/tftpd-hpa
    echo "TFTP_ADDRESS=\":69\"" >> /etc/default/tftpd-hpa
    echo "TFTP_OPTIONS=\"--secure --create\"" >> /etc/default/tftpd-hpa
	
	systemctl restart tftpd-hpa
}

function ubuntu_nfs_init()
{
	apt install nfs-kernel-server
	
	cp /etc/exports /etc/exports.ORIGINAL
	
	echo "$NFSROOT       *(rw,sync,insecure,no_root_squash,no_subtree_check)" >> /etc/exports
	
	systemctl enable nfs-kernel-server
	systemctl restart nfs-kernel-server
}

function tftp_init() 
{
    echo "--------------------------------------------------------"
    echo "Install TFTP server at $TFTPROOT"
    echo "--------------------------------------------------------"
	
	mkdir -p $TFTPROOT
	chmod 777 $TFTPROOT
	
	if [ $DISTRO = "Ubuntu" ] 
	then
	    ubuntu_tftp_init
	fi
}

function nfs_init() 
{
    echo "--------------------------------------------------------"
    echo "Install NFS  server at $NFSROOT"
    echo "--------------------------------------------------------"
	
	mkdir -p $NFSROOT

	if [ $DISTRO = "Ubuntu" ] 
	then
	    ubuntu_nfs_init
	fi
}

function envinit() 
{
    GetDistroName

    echo "Initialize embedded linux development environment for $DISTRO ... "
	
	tftp_init
	
	nfs_init
}

# Process all arguments
while getopts "n:t:" opt
do
    case $opt in
        n) NFSROOT=$OPTARG
           ;;
        t) TFTPROOT=$OPTARG
           ;;
        ?) usage
           ;;
    esac
done

# Skip all vaild arguments
shift $(($OPTIND - 1))

# Unknown arguments, show usage
if [ $# -gt 0 ] ; then
    usage
fi

envinit
