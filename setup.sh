#!/bin/sh

set -e -u

shmsys=/kosie-root
mirror=http://us-west-2.ec2.archive.ubuntu.com/ubuntu
user=${SUDO_USER-USER}

apt update
apt install debootstrap
debootstrap --variant minbase --include=sudo,screen,isc-dhcp-client,openssh-server trusty "$shmsys" "$mirror"

chroot "$shmsys" adduser --gecos "" "$user"
chroot "$shmsys" adduser "$user" sudo

cp -var --parents /opt/kite /etc/init/klient.conf /etc/init.d/klient /usr/share/doc/klient /etc/kite /etc/network/interfaces.d/*.cfg /etc/ssh/ssh_host_* "$shmsys"

cat > /usr/share/initramfs-tools/scripts/init-bottom/kosie_move <<EOF
#!/bin/sh

set -e

case "\$1" in
	prereqs) exit 0;;
esac

mount -o remount,rw "\$rootmnt"
cp "\$rootmnt"/initrd-backup.img "\$rootmnt"/initrd.img
mount -o remount,ro "\$rootmnt"

echo > /dev/kmsg "hello from kosie_move"

shmroot=\$(mktemp -d)
mount -t tmpfs none "\$shmroot"
cp -a "\$rootmnt"$shmsys/* "\$shmroot"
umount "\$rootmnt"
mount -o move "\$shmroot" "\$rootmnt"
rmdir "\$shmroot"

echo > /dev/kmsg "goodbye from kosie_move"
EOF
chmod +x /usr/share/initramfs-tools/scripts/init-bottom/kosie_move
update-initramfs -u
