#!/bin/bash

# Run with a channel name and a version string:
#
#  $ ./fix_vagrant.sh alpha 1800.1.0
#
# To override the gpg command to a custom one like gpg2:
#
#  $ GPG=gpg2 ./fix_vagrant.sh alpha 1800.1.0

set -ex

CHANNEL=$1
VERSION=$2
readonly GPG="${GPG:-gpg}"

PREFIX="https://storage.googleapis.com/flatcar-jenkins/$CHANNEL/boards/amd64-usr/$VERSION"

for img in flatcar_production_vagrant flatcar_production_vagrant_virtualbox flatcar_production_vagrant_vmware_fusion flatcar_production_vagrant_parallels; do
    wget "$PREFIX/$img".json
    wget "$PREFIX/$img".DIGESTS
    wget "$PREFIX/$img".box.DIGESTS
done

sed -i "s%https://flatcar-jenkins/${CHANNEL}%https://${CHANNEL}.release.flatcar-linux.net%g" *.json

for f in *.DIGESTS; do
    head -6 $f > $f.tmp
    mv $f.tmp $f
done

for f in *.json; do
    fname="${f%.*}"
    echo '# MD5 HASH' >> ${fname}.DIGESTS
    md5sum $f >> ${fname}.DIGESTS
    echo '# SHA1 HASH' >> ${fname}.DIGESTS
    sha1sum $f >> ${fname}.DIGESTS
    echo '# SHA512 HASH' >> ${fname}.DIGESTS
    sha512sum $f >> ${fname}.DIGESTS

    echo '# MD5 HASH' >> ${fname}.box.DIGESTS
    md5sum $f >> ${fname}.box.DIGESTS
    echo '# SHA1 HASH' >> ${fname}.box.DIGESTS
    sha1sum $f >> ${fname}.box.DIGESTS
    echo '# SHA512 HASH' >> ${fname}.box.DIGESTS
    sha512sum $f >> ${fname}.box.DIGESTS
done

for f in *.json; do
    ${GPG} --sign --detach -u F88CFEDEFF29A5B4D9523864E25D9AED0593B34A "$f"
done
for f in *.DIGESTS; do
    ${GPG} --sign --detach -u F88CFEDEFF29A5B4D9523864E25D9AED0593B34A "$f"
    ${GPG} --clear-sign --armor --detach -u F88CFEDEFF29A5B4D9523864E25D9AED0593B34A "$f"
done

scp flatcar_* "core@origin.release.flatcar-linux.net:/var/www/origin.release.flatcar-linux.net/${CHANNEL}/amd64-usr/${VERSION}/"

rm flatcar_*
