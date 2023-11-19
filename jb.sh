#!/bin/sh
#
# Quick'n dirty JB key install script for KindleBreak.
# Based on the "emergency" script from the Hotfix/Bridge restoration package.
#
# $Id: jb.sh 18327 2021-03-24 18:08:54Z NiLuJe $
#
##

# Helper functions, in case the bridge was still kicking.
make_mutable() {
	local my_path="${1}"
	# NOTE: Can't do that on symlinks, hence the hoop-jumping...
	if [ -d "${my_path}" ] ; then
		find "${my_path}" -type d -exec chattr -i '{}' \;
		find "${my_path}" -type f -exec chattr -i '{}' \;
	elif [ -f "${my_path}" ] ; then
		chattr -i "${my_path}"
	fi
}

# We actually do need that one
make_immutable() {
	local my_path="${1}"
	if [ -d "${my_path}" ] ; then
		find "${my_path}" -type d -exec chattr +i '{}' \;
		find "${my_path}" -type f -exec chattr +i '{}' \;
	elif [ -f "${my_path}" ] ; then
		chattr +i "${my_path}"
	fi
}

# KindleBreak specificity, as it may be hung/hogging resources.
killall mesquite
killall stackdumpd

# For logging
[ -f "/etc/upstart/functions" ] && source "/etc/upstart/functions"
KINDLEBREAK_LOG="/mnt/us/kindlebreak_log.txt"
rm -f "${KINDLEBREAK_LOG}"

kb_log() {
	f_log "I" "kindlebreak" "${2}" "" "${1}"
	echo "${1}" >> "${KINDLEBREAK_LOG}"
}

kb_log "Loaded logging functions" "main"

# Duh'
mntroot rw

# JB first
if [ -f "/etc/uks/pubdevkey01.pem" ] ; then
	make_mutable "/etc/uks/pubdevkey01.pem"
	rm -f "/etc/uks/pubdevkey01.pem"
	kb_log "Removed existing developer key" "jb"
else
	kb_log "Didn't find existing developer key" "jb"
fi

cat > "/etc/uks/pubdevkey01.pem" << EOF
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDJn1jWU+xxVv/eRKfCPR9e47lP
WN2rH33z9QbfnqmCxBRLP6mMjGy6APyycQXg3nPi5fcb75alZo+Oh012HpMe9Lnp
eEgloIdm1E4LOsyrz4kttQtGRlzCErmBGt6+cAVEV86y2phOJ3mLk0Ek9UQXbIUf
rvyJnS2MKLG2cczjlQIDAQAB
-----END PUBLIC KEY-----
EOF
RET="$?"

if [ -f "/etc/uks/pubdevkey01.pem" ] ; then
	kb_log "Created developer key (${RET})" "jb"
else
	kb_log "Unable to create developer key (${RET})" "jb"
fi

chown root:root "/etc/uks/pubdevkey01.pem"
chmod 0644 "/etc/uks/pubdevkey01.pem"
make_immutable "/etc/uks/pubdevkey01.pem"

kb_log "Updated permissions for developer key" "jb"

# Make sure we can use UYK for OTA packages on FW >= 5.12.x
make_mutable "/PRE_GM_DEBUGGING_FEATURES_ENABLED__REMOVE_AT_GMC"
rm -rf "/PRE_GM_DEBUGGING_FEATURES_ENABLED__REMOVE_AT_GMC"
touch "/PRE_GM_DEBUGGING_FEATURES_ENABLED__REMOVE_AT_GMC"
make_immutable "/PRE_GM_DEBUGGING_FEATURES_ENABLED__REMOVE_AT_GMC"

kb_log "Enabled developer flag" "br"

# Bye
sync
mntroot ro

kb_log "Finished installing jailbreak, restarting..." "main"

# Cleanup
rm -f "/mnt/us/kindlebreak.html"
rm -f "/mnt/us/kindlebreak.jxr"
rm -f "/mnt/us/jb.sh"
rm -f "/mnt/us/jb"
sync

# Reboot
reboot -f
