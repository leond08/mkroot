#!/bin/echo Use "OVERLAY=overlay.sh ./mkroot.sh"

# Example overlay file, adding dropbear (which requires zlib)

echo === download source

download a4d316c404ff54ca545ea71a27af7dbc29817088 \
  http://zlib.net/zlib-1.2.8.tar.gz

download 1b112e32da9af8f8aa0a6e6f64f440c039459a49 \
  https://matt.ucc.asn.au/dropbear/releases/dropbear-2016.73.tar.bz2

echo === Native build static zlib

setupfor zlib
# They keep checking in broken generated files.
rm -f Makefile zconf.h &&
CC=${CROSS_COMPILE}cc LD=${CROSS_COMPILE}ld AS=${CROSS_COMPILE}as ./configure &&
make -j $(nproc) || exit 1

# do _not_ cleanup zlib, we need the files we just built for dropbear
cd ..

echo === $HOST Native build static dropbear

setupfor dropbear
# Repeat after me: "autoconf is useless"
echo 'echo "$@"' > config.sub &&
ZLIB="$(echo ../zlib*)" &&
CFLAGS="-I $ZLIB -Os" LDFLAGS="--static -L $ZLIB" ./configure \
  --host=${CROSS_BASE%-} &&
sed -i 's@/usr/bin/dbclient@ssh@' options.h &&
make -j $(nproc) PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp" MULTI=1 SCPPROGRESS=1 &&
${CROSS_COMPILE}strip dropbearmulti &&
mkdir -p "$OUT/bin" &&
cp dropbearmulti "$OUT"/bin || exit 1
for i in "$OUT"/bin/{ssh,sshd,scp,dropbearkey}
do
  ln -s dropbearmulti $i || exit 1
done
cleanup

rm -rf zlib-*
