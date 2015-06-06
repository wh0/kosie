#!/bin/sh

set -e -u

shmsys=/kosie-root
mirror=http://us-west-2.ec2.archive.ubuntu.com/ubuntu

apt update
apt install debootstrap
sudo debootstrap --variant minbase --include=sudo,screen,openssh-server trusty "$shmsys" "$mirror"

chroot "$shmsys" adduser --gecos "" "$USER"
chroot "$shmsys" adduser "$USER" sudo

cp -a --parents /opt/kite/klient/klient /etc/init/klient.conf /etc/init.d/klient /usr/share/doc/klient/changelog.gz /etc/kite/kite.key "$shmsys"

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
