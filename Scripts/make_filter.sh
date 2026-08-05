#!/bin/bash

CONFIG="Config/config.json"


NAME=$(python3 -c "import json;print(json.load(open('$CONFIG'))['bundle'])")


cat > Filter.plist <<EOF
{
    Filter = {
        Bundles = (
            "$NAME"
        );
    };
}
EOF


echo "Filter.plist generated"
