#!/bin/sh

XML=$1
XML=`readlink -f ${XML}`
IPCFG=$2

TIMEOUT=600

if [ ! -f "${XML}" ]; then
    echo "ERROR: File Not Found : ${XML}"
    exit 1
fi

#IPCFG=`grep ipaddress@ ${XML} | cut -d '@' -f 2`
if [ ! "${IPCFG}" ]; then
    echo "ERROR: ip params not found from xml."
    exit 1
fi

DN=`grep "<name>.*</name>" ${XML} | cut -d '>' -f 2 | cut -d '<' -f 1`
echo ${DN} ${IPCFG}
IF=`echo ${IPCFG} | cut -d ':' -f 1`
IP=`echo ${IPCFG} | cut -d ':' -f 2`
PF=`echo ${IPCFG} | cut -d ':' -f 3`


_chg_ip() {
    F_UDEV=/etc/udev/rules.d/70-persistent-net.rules
    virt-edit -d ${DN} ${F_UDEV} -e "s/.*//"
    F_NIC=/etc/sysconfig/network-scripts/ifcfg-${IF}
    virt-edit -d ${DN} ${F_NIC} -e "s/IPADDR=.*/IPADDR=${IP}/"
    virt-edit -d ${DN} ${F_NIC} -e "s/PREFIX=.*/PREFIX=${PF}/"
#    virt-cat  -d ${DN} ${F_NIC}
}

_chk_ip() {
    echo
    for i in `seq 0 ${TIMEOUT}`
    do
        ping -w 1 ${IP} >/dev/null
        test $? -eq 0 && return 0
        sleep 1; printf "."
    done
    return 1
}

_kvm_shutdown() {
    domain=$1
    virsh shutdown ${domain}
    echo
    for i in `seq 0 ${TIMEOUT}`
    do
        virsh list | grep -q ${domain}
        test $? -ne 0 && return 0
        sleep 1; printf "."
    done
    return 1
}

_kvm_undef() {
    rc=0
    _kvm_shutdown ${DN} 2>/dev/null
    rc=$?
    echo
    virsh undefine ${DN} 2>/dev/null
    return ${rc}
}

_kvm_def() {
    virsh define ${XML}
    virsh autostart ${DN}
}

_kvm_start() {
    virsh start ${DN}
}


case $2 in
undef)
    _kvm_undef || exit 124
    ;;
*)
    _kvm_undef || exit 124
    _kvm_def
    _chg_ip
    _kvm_start
    _chk_ip || exit 124
esac

echo
echo Done.


# libs
# hexedit-1.2.13-5.el7.x86_64.rpm
# libguestfs-tools-1.28.1-1.55.el7.centos.noarch.rpm
# libguestfs-tools-c-1.28.1-1.55.el7.centos.x86_64.rpm
# perl-libintl-1.20-12.el7.x86_64.rpm
# perl-Sys-Guestfs-1.28.1-1.55.el7.centos.x86_64.rpm
# perl-Sys-Virt-1.2.17-2.el7.x86_64.rpm

