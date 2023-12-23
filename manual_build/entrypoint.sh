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
    _origIFS="$IFS"
    IFS=','
    for AGID in $PAGID; do
        AGID=$(echo "$AGID" | tr -d '[:space:]"')
        addgroup -g "$AGID" "qbtGroup-$AGID"
        addgroup qbtUser "qbtGroup-$AGID"
    done
    IFS="$_origIFS"
fi

if [ ! -f "$qbtConfigFile" ]; then
    mkdir -p "$(dirname $qbtConfigFile)"
    cat << EOF > "$qbtConfigFile"
[BitTorrent]
Session\DefaultSavePath=$downloadsPath
Session\Port=6881
Session\TempPath=$downloadsPath/temp

[LegalNotice]
Accepted=false
EOF
fi

_legalNotice=$(echo "$QBT_LEGAL_NOTICE" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
if [ "$_legalNotice" = "confirm" ]; then
    sed -i '/^\[LegalNotice\]$/{$!{N;s|\(\[LegalNotice\]\nAccepted=\).*|\1true|}}' "$qbtConfigFile"
else
    # for backward compatibility
    # TODO: remove in next major version release
    _eula=$(echo "$QBT_EULA" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    if [ "$_eula" = "accept" ]; then
        sed -i '/^\[LegalNotice\]$/{$!{N;s|\(\[LegalNotice\]\nAccepted=\).*|\1true|}}' "$qbtConfigFile"
    else
        sed -i '/^\[LegalNotice\]$/{$!{N;s|\(\[LegalNotice\]\nAccepted=\).*|\1false|}}' "$qbtConfigFile"
    fi
fi

if [ -z "$QBT_WEBUI_PORT" ]; then
    QBT_WEBUI_PORT=8080
fi

# those are owned by root by default
# don't change existing files owner in `$downloadsPath`
if [ -d "$downloadsPath" ]; then
    chown qbtUser:qbtUser "$downloadsPath"
fi
if [ -d "$profilePath" ]; then
    chown qbtUser:qbtUser -R "$profilePath"
fi

# set umask just before starting qbt
if [ -n "$UMASK" ]; then
    umask "$UMASK"
fi

exec \
    doas -u qbtUser \
        qbittorrent-nox \
            --profile="$profilePath" \
            --webui-port="$QBT_WEBUI_PORT" \
            "$@"
