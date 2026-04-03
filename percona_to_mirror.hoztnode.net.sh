#!/usr/bin/bash
#
PERCONA_URL='http://repo.percona.com'
HOZTNODE_URL='https://mirror.hoztnode.net/percona'
#
PERCONA_PREL='/etc/yum.repos.d/percona-prel-release.repo'
PERCONA_PS80='/etc/yum.repos.d/percona-ps-80-release.repo'
PERCONA_TELEMETRY='/etc/yum.repos.d/percona-telemetry-release.repo'
PERCONA_TOOLS='/etc/yum.repos.d/percona-tools-release.repo'
#
echo "Backup percona-*.repo files"
cp -f ${PERCONA_PREL} ${PERCONA_PREL}.backup > /dev/null 2>&1
cp -f ${PERCONA_PS80} ${PERCONA_PS80}.backup > /dev/null 2>&1
cp -f ${PERCONA_TELEMETRY} ${PERCONA_TELEMETRY}.backup > /dev/null 2>&1
cp -f ${PERCONA_TOOLS} ${PERCONA_TOOLS}.backup > /dev/null 2>&1
#
echo "Replace Percona url to mirror.hoztnode.net in percona-*.repo files"
sed -i "s|${PERCONA_URL}|${HOZTNODE_URL}|g" ${PERCONA_PREL} > /dev/null 2>&1
sed -i "s|${PERCONA_URL}|${HOZTNODE_URL}|g" ${PERCONA_PS80} > /dev/null 2>&1
sed -i "s|${PERCONA_URL}|${HOZTNODE_URL}|g" ${PERCONA_TELEMETRY} > /dev/null 2>&1
sed -i "s|${PERCONA_URL}|${HOZTNODE_URL}|g" ${PERCONA_TOOLS} > /dev/null 2>&1
#
echo "Clear cache"
dnf clean all > /dev/null 2>&1
echo "All done!"
#
