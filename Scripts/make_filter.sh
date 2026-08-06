#!/bin/bash


CONFIG="Projects/$PROJECT/config.json"


if [ ! -f "$CONFIG" ]; then

    echo "❌ Config.json not found: $CONFIG"

    exit 1

fi


BUNDLE=$(python3 -c "import json;print(json.load(open('$CONFIG'))['bundle'])")


cat > Filter.plist <<EOF
{
    Filter = {
        Bundles = (
            "$BUNDLE"
        );
    };
}
EOF


echo "===== Filter.plist generated ====="

cat Filter.plist
