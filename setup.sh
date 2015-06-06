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

cat > /usr/share/initramfs-tools/scripts/local-bottom/kosie_move <<EOF
#!/bin/sh

set -e

case "\$1" in
	prereqs) exit 0;;
esac

shmroot=\$(mktemp -d)
mount -t tmpfs none "\$shmroot"
cp -a "\$rootmnt"$shmsys/* "\$shmroot"
umount "\$rootmnt"
mount -o move "\$shmroot" "\$rootmnt"
rmdir "\$shmroot"
EOF
chmod +x /usr/share/initramfs-tools/scripts/local-bottom/kosie_move
update-initramfs -u
