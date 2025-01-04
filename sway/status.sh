MEDIA_STATUS=$(playerctl status)
MEDIA_CONTENT=$(playerctl metadata --format '"{{title}}" by {{artist}}')
VOLUME=$(wpctl get-volume \@DEFAULT_SINK@)
DATE=$(date +'%Y-%m-%d %X')

echo "$MEDIA_STATUS $MEDIA_CONTENT | $VOLUME | $DATE"
