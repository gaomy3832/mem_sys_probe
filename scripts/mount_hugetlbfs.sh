
mntpnt=mnt-hugetlbfs

mnt() {
    mkdir -p ${mntpnt}
    sudo mount -t hugetlbfs none ${mntpnt} -o uid=$(id -u),gid=$(id -g)
    echo "Mount ${mntpnt} as type hugetlbfs"
}

umt() {
    if $( mountpoint -q ${mntpnt} ); then
        sudo umount ${mntpnt}
        sleep 1   # wait for umount to finish, avoid device busy error
        rm -rf ${mntpnt}
        echo "Unmount ${mntpnt}"
    fi
}

if [ "$#" -eq 1 ] && ( [ "$1" == "-m" ] || [ "$1" == "-mount" ] ); then
    mnt
elif [ "$#" -eq 1 ] && ( [ "$1" == "-u" ] || [ "$1" == "-umount" ] ); then
    umt
else
    echo "Usage: mount_hugetlbfs.sh [-m(ount)] [-u(mount)]" >&2
    exit 1
fi

