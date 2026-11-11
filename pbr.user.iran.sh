#!/bin/sh

TARGET_INTERFACE="${TARGET_INTERFACE:-wan}"
TARGET_SET="${TARGET_SET:-pbr_${TARGET_INTERFACE}_4_dst_ip_user}"
TARGET_IPSET="${TARGET_IPSET:-pbr_${TARGET_INTERFACE}_4_dst_net_user}"
TARGET_TABLE="${TARGET_TABLE:-inet fw4}"
MIN_SOURCE_PREFIXES=100
MAX_SOURCE_PREFIXES=3000
MAX_FINAL_PREFIXES=3000
WORK_DIR="/tmp/pbr-iran.$$"

log() {
    printf 'pbr-iran: %s\n' "$*" >&2
}

fetch_url() {
    if command -v uclient-fetch >/dev/null 2>&1; then
        uclient-fetch -qO- "$1" 2>/dev/null
    elif command -v curl >/dev/null 2>&1; then
        curl -fsSL --max-time 30 "$1" 2>/dev/null
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- "$1" 2>/dev/null
    else
        log "uclient-fetch, curl, or wget is required"
        return 1
    fi
}

validate_source() {
    grep -Eo '[0-9]{1,3}(\.[0-9]{1,3}){3}/([0-9]|[12][0-9]|3[0-2])' "$1" |
        awk -F '[./]' '
            function overlaps(start, end, network, mask, size) {
                size = 2 ^ (32 - mask)
                return start < network + size && end >= network
            }
            NF == 5 &&
            $1 ~ /^[0-9]+$/ && $1 <= 255 &&
            $2 ~ /^[0-9]+$/ && $2 <= 255 &&
            $3 ~ /^[0-9]+$/ && $3 <= 255 &&
            $4 ~ /^[0-9]+$/ && $4 <= 255 &&
            $5 ~ /^[0-9]+$/ && $5 <= 32 {
                address = (($1 * 256 + $2) * 256 + $3) * 256 + $4
                size = 2 ^ (32 - $5)
                if (int(address / size) * size != address)
                    next
                end = address + size - 1
                if (overlaps(address, end, 0, 8) ||
                    overlaps(address, end, 167772160, 8) ||
                    overlaps(address, end, 1681915904, 10) ||
                    overlaps(address, end, 2130706432, 8) ||
                    overlaps(address, end, 2851995648, 16) ||
                    overlaps(address, end, 2886729728, 12) ||
                    overlaps(address, end, 3221225472, 24) ||
                    overlaps(address, end, 3221225984, 24) ||
                    overlaps(address, end, 3227017984, 24) ||
                    overlaps(address, end, 3232235520, 16) ||
                    overlaps(address, end, 3323068416, 15) ||
                    overlaps(address, end, 3325256704, 24) ||
                    overlaps(address, end, 3405803776, 24) ||
                    overlaps(address, end, 3758096384, 4) ||
                    overlaps(address, end, 4026531840, 4))
                    next
                print $1 "." $2 "." $3 "." $4 "/" $5
            }
        ' > "$2"
}

if ! mkdir "$WORK_DIR"; then
    log "cannot create temporary directory"
    _ret=1
else
    _ret=1
    source_number=0
    primary_source_count=0
    community_source_count=0
    primary_file="$WORK_DIR/primary-prefixes"
    community_file="$WORK_DIR/community-prefixes"

    for source_url in \
        'https://stat.ripe.net/data/country-resource-list/data.json?resource=IR&v4_format=prefix' \
        'https://www.ipdeny.com/ipblocks/data/countries/ir.zone' \
        'https://raw.githubusercontent.com/MrAriaNet/Get-IP-Iran/main/list.rsc' \
        'https://raw.githubusercontent.com/farshidmousavii/iran-ip-ranges/main/dist/raw/ipv4.txt'; do
        source_number=$((source_number + 1))
        source_file="$WORK_DIR/source-$source_number"
        valid_file="$WORK_DIR/valid-$source_number"

        if ! fetch_url "$source_url" > "$source_file"; then
            log "source $source_url is unavailable; ignoring it"
            continue
        fi

        validate_source "$source_file" "$valid_file"
        sort -u "$valid_file" -o "$valid_file"
        prefix_count=$(wc -l < "$valid_file" | tr -d ' ')
        if [ "$prefix_count" -lt "$MIN_SOURCE_PREFIXES" ]; then
            log "source $source_url returned too few valid IPv4 prefixes ($prefix_count); ignoring it"
            continue
        fi

        if [ "$prefix_count" -gt "$MAX_SOURCE_PREFIXES" ]; then
            log "source $source_url returned too many IPv4 prefixes ($prefix_count); ignoring it"
            continue
        fi

        if [ "$source_number" -le 2 ]; then
            cat "$valid_file" >> "$primary_file"
            primary_source_count=$((primary_source_count + 1))
        else
            cat "$valid_file" >> "$community_file"
            community_source_count=$((community_source_count + 1))
        fi
    done

    if [ -s "$primary_file" ] && [ -s "$community_file" ]; then
        sort -u "$primary_file" > "$WORK_DIR/primary-unique"
        sort -u "$community_file" > "$WORK_DIR/community-unique"
        comm -12 "$WORK_DIR/primary-unique" "$WORK_DIR/community-unique" \
            > "$WORK_DIR/unique-prefixes"
        prefix_count=$(wc -l < "$WORK_DIR/unique-prefixes" | tr -d ' ')

        if [ "$prefix_count" -lt "$MIN_SOURCE_PREFIXES" ]; then
            log "source consensus contains too few IPv4 prefixes ($prefix_count); existing routing rules were left unchanged"
        elif [ "$prefix_count" -gt "$MAX_FINAL_PREFIXES" ]; then
            log "source consensus contains too many IPv4 prefixes ($prefix_count); existing routing rules were left unchanged"
        elif command -v ipset >/dev/null 2>&1 && ipset -q list "$TARGET_IPSET" >/dev/null 2>&1; then
            if awk -v ipset="$TARGET_IPSET" '{ print "add " ipset " " $1 }' \
                "$WORK_DIR/unique-prefixes" | ipset restore -!; then
                _ret=0
                log "updated $TARGET_IPSET with $prefix_count unique prefixes (primary sources: $primary_source_count, community sources: $community_source_count)"
            else
                log "failed to update ipset $TARGET_IPSET"
            fi
        else
            nft_cmd="${nft:-$(command -v nft)}"
            if [ -n "$nft_cmd" ] && [ -x "$nft_cmd" ] &&
                "$nft_cmd" list set "$TARGET_TABLE" "$TARGET_SET" >/dev/null 2>&1; then
                {
                    printf 'add element %s %s { ' "$TARGET_TABLE" "$TARGET_SET"
                    awk 'NR > 1 { printf ", " } { printf "%s", $0 } END { print "" }' \
                        "$WORK_DIR/unique-prefixes"
                    printf ' }\n'
                } > "$WORK_DIR/update.nft"

                if "$nft_cmd" -exist -f "$WORK_DIR/update.nft"; then
                    _ret=0
                    log "updated $TARGET_SET with $prefix_count unique prefixes (primary sources: $primary_source_count, community sources: $community_source_count)"
                else
                    log "failed to update nft set $TARGET_SET"
                fi
            else
                log "nft set $TARGET_TABLE $TARGET_SET was not found"
            fi
        fi
    else
        log "no valid list from both a primary source and a community source; existing routing rules were left unchanged"
    fi

    rm -f "$WORK_DIR"/source-* "$WORK_DIR"/valid-* \
        "$WORK_DIR"/primary-prefixes "$WORK_DIR"/community-prefixes \
        "$WORK_DIR"/primary-unique "$WORK_DIR"/community-unique \
        "$WORK_DIR"/unique-prefixes "$WORK_DIR"/update.nft
    rmdir "$WORK_DIR"
fi

return "$_ret" 2>/dev/null || exit "$_ret"
