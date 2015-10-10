#!/bin/sh

rm -fr target
mkdir -p target/ki-eye/artifacts
cp -r scripts target/ki-eye/

chmod 0755 target//ki-eye/scripts/add_delay
chmod 0755 target//ki-eye/scripts/add_partition
chmod 0755 target//ki-eye/scripts/add_ssd
chmod 0755 target//ki-eye/scripts/crypt_passwd
chmod 0755 target//ki-eye/scripts/del_delay
chmod 0755 target//ki-eye/scripts/del_partition
chmod 0755 target//ki-eye/scripts/foreachhost
chmod 0755 target//ki-eye/scripts/gettrace
chmod 0755 target//ki-eye/scripts/install
chmod 0755 target//ki-eye/scripts/netcheck
chmod 0755 target//ki-eye/scripts/replace
chmod 0755 target//ki-eye/scripts/reset
chmod 0755 target//ki-eye/scripts/rss_monitor
chmod 0755 target//ki-eye/scripts/runit
chmod 0755 target//ki-eye/scripts/shape
chmod 0755 target//ki-eye/scripts/userman

chmod 0644 target//ki-eye/scripts/hosts*

(
    cd target
    tar czvf ki-eye.tgz ki-eye
)
