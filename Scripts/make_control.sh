#!/bin/bash


CONFIG="Config/config.json"


NAME=$(python3 -c "import json;print(json.load(open('$CONFIG'))['name'])")

VERSION=$(python3 -c "import json;print(json.load(open('$CONFIG'))['version'])")

DESC=$(python3 -c "import json;print(json.load(open('$CONFIG'))['description'])")


cat > control <<EOF
Package: com.minis.$NAME
Name: $NAME
Depends: mobilesubstrate
Architecture: iphoneos-arm
Description: $DESC
Maintainer: Minis
Author: Minis
Section: Tweaks
Version: $VERSION
EOF


echo "control generated"
