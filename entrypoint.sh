#!/bin/sh

downloadsPath="/downloads"
profilePath="/config"
qbtConfigFile="$profilePath/qBittorrent/config/qBittorrent.conf"

if [ -n "$PUID" ]; then
    sed -i "s|^qbtUser:x:[0-9]*:|qbtUser:x:$PUID:|g" /etc/passwd
fi

if [ -n "$PGID" ]; then
    sed -i "s|^\(qbtUser:x:[0-9]*\):[0-9]*:|\1:$PGID:|g" /etc/passwd
    sed -i "s|^qbtUser:x:[0-9]*:|qbtUser:x:$PGID:|g" /etc/group
fi

if [ -n "$PAGID" ]; then
    _origIFS=$IFS
    IFS=','
    for AGID in $PAGID; do
        AGID=$(echo "$AGID" | tr -d '[:space:]"')
        addgroup -g "$AGID" "qbtGroup-$AGID"
        addgroup qbtUser "qbtGroup-$AGID"
    done
    IFS=$_origIFS
fi

if [ ! -f "$qbtConfigFile" ]; then
    mkdir -p "$(dirname $qbtConfigFile)"
    cat << EOF > "$qbtConfigFile"
[BitTorrent]
Session\DefaultSavePath=/downloads
Session\Port=6881
Session\TempPath=/downloads/temp

[LegalNotice]
Accepted=false
EOF

    if [ "$QBT_EULA" = "accept" ]; then
        sed -i '/^\[LegalNotice\]$/{$!{N;s|\(\[LegalNotice\]\nAccepted=\).*|\1true|}}' "$qbtConfigFile"
    else
        sed -i '/^\[LegalNotice\]$/{$!{N;s|\(\[LegalNotice\]\nAccepted=\).*|\1false|}}' "$qbtConfigFile"
    fi
fi

# those are owned by root by default
# don't change existing files owner in `$downloadsPath`
chown qbtUser:qbtUser "$downloadsPath"
chown qbtUser:qbtUser -R "$profilePath"

# set umask just before starting qbt
if [ -n "$UMASK" ]; then
    umask "$UMASK"
fi

doas -u qbtUser \
    qbittorrent-nox \
        --profile="$profilePath" \
        --webui-port="$QBT_WEBUI_PORT" \
        "$@"
