# vim: set ts=4 sw=4 et:

msg "Mounting pseudo-filesystems..."
if [ ! -c /dev/null ] ; then
    # We need /dev/null to redirect stdout, if it is missing the shell will 
	# error and not run the command. To be on the safe side we warn the user
    # just like runit does, when /dev/console is missing and mount devtmpfs
    # early so we can continue booting. Alternatively we could just always mount
    # devtmpfs first, but that just hides potential problems from the user.
    echo "warning: /dev/null is missing or not a character device, mounting devtmpfs early."
    mountpoint -q /dev || mount -o mode=0755,nosuid -t devtmpfs dev /dev
fi

# First we try to remount the fs, in case it got mounted by initramfs, then we
# try to mount it with options from fstab and it this fails we mount it with
# default options.
# The last command is not redirected to /dev/null so an error is shown, when all
# three commands fail.
mount -o remount /proc 2> /dev/null \
	|| mount /proc 2> /dev/null \
	|| mount -o nosuid,noexec,nodev -t proc proc /proc
mount -o remount /sys 2> /dev/null \
	|| mount /sys 2> /dev/null \
	|| mount -o nosuid,noexec,nodev -t sysfs sys /sys
mount -o remount /run 2> /dev/null \
	|| mount /run 2> /dev/null \
	|| mount -o mode=0755,nosuid,nodev -t tmpfs run /run
mount -o remount /dev 2> /dev/null \
	|| mount /dev 2> /dev/null \
	|| mount -o mode=0755,nosuid -t devtmpfs dev /dev
mkdir -p -m0755 /run/runit /run/lvm /run/user /run/lock /run/log /dev/pts /dev/shm
mount -o remount /dev/pts 2> /dev/null \
	|| mount /dev/pts 2> /dev/null \
	|| mount -o mode=0620,gid=5,nosuid,noexec -n -t devpts devpts /dev/pts
mount -o remount /dev/shm 2> /dev/null \
	|| mount /dev/shm 2> /dev/null \
	|| mount -o mode=1777,nosuid,nodev -n -t tmpfs shm /dev/shm

if [ -z "$VIRTUALIZATION" ]; then
    mountpoint -q /sys/fs/cgroup || mount -o mode=0755 -t tmpfs cgroup /sys/fs/cgroup
    awk '$4 == 1 { system("mountpoint -q /sys/fs/cgroup/" $1 " || { mkdir -p /sys/fs/cgroup/" $1 " && mount -t cgroup -o " $1 " cgroup /sys/fs/cgroup/" $1 " ;}" ) }' /proc/cgroups
fi
