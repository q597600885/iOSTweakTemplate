#!/bin/bash

CONFIG="Config/config.json"

if [ ! -f "$CONFIG" ]; then
    echo "Config file not found!"
    exit 1
fi


NAME=$(python3 -c "import json;print(json.load(open('$CONFIG'))['name'])")

BUNDLE=$(python3 -c "import json;print(json.load(open('$CONFIG'))['bundle'])")

VERSION=$(python3 -c "import json;print(json.load(open('$CONFIG'))['version'])")


cat > tweak_config.mk <<EOF
TWEAK_NAME = $NAME

PACKAGE_NAME = com.minis.$NAME

BUNDLE_ID = $BUNDLE

VERSION = $VERSION
EOF


echo "===== Generated tweak_config.mk ====="

cat tweak_config.mk
