#!/bin/sh
TARGET_INTERFACE='wan'
TARGET_NFTSET_4="pbr_${TARGET_INTERFACE}_4_dst_ip_user"
TARGET_TABLE='inet fw4'
TARGET_URL="https://raw.githubusercontent.com/MrAriaNet/Get-IP-Iran/main/list.rsc"
TARGET_DL_FILE_4="/var/pbr_tmp_iran_ip_ranges.ipv4"

_ret=0

if [ ! -s "$TARGET_DL_FILE_4" ]; then
        uclient-fetch --no-check-certificate -qO- "$TARGET_URL" 2>/dev/null | grep -oE "\b[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+\b" > "$TARGET_DL_FILE_4"
fi

if [ -s "$TARGET_DL_FILE_4" ]; then
        params=
        while read -r p; do params="${params:+$params, }${p}"; done < "$TARGET_DL_FILE_4"
        [ -n "$params" ] && nft "add element $TARGET_TABLE $TARGET_NFTSET_4 { $params }" || _ret=1
fi


return $_ret

# source is https://github.com/WhoisGray/openwrt-pbr-iran-rules
