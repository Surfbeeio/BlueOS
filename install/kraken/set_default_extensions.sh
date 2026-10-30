#!/usr/bin/env bash

# Versions are pinned: newer SonarView releases broke the dual Omniscan 3D setup that works on 1.14.83

SONARVIEW_TAG="1.14.83"
BLUEOS_PROXY_TAG="v1.0.6"

# Images pulling

docker pull "nicknothom/sonarview:$SONARVIEW_TAG"
docker pull "williangalvani/blueos-extension-proxy:$BLUEOS_PROXY_TAG"

# Settings creation

SETTINGS_BASE_DIR="/root/.config/blueos/kraken"

mkdir -p "${SETTINGS_BASE_DIR}"

# Check if the directory creation was successful
if [[ ! -d "${SETTINGS_BASE_DIR}" ]]; then
  echo "Failed to create directory ${SETTINGS_BASE_DIR}"
  exit 1
fi

# Creates kraken V2 settings with default extensions

cat > "${SETTINGS_BASE_DIR}/settings-2.json" <<EOF
{
  "VERSION": 2,
  "extensions": [
    {
      "docker": "nicknothom/sonarview",
      "enabled": true,
      "identifier": "ceruleansonar.sonarview",
      "name": "SonarView",
      "permissions": "{\"HostConfig\":{\"NetworkMode\":\"host\",\"Binds\":[\"/usr/blueos/userdata/SonarView:/userdata\"],\"ReadonlyRootfs\":true,\"ExtraHosts\":[\"host.docker.internal:127.0.1.1\",\"blueos.local:127.0.1.1\"]}}",
      "tag": "$SONARVIEW_TAG",
      "user_permissions": "{\"Env\":[\"ENABLE_OS3D=false\"],\"HostConfig\":{\"NetworkMode\":\"host\",\"Binds\":[\"/usr/blueos/userdata/SonarView:/userdata\"],\"ReadonlyRootfs\":true,\"ExtraHosts\":[\"host.docker.internal:127.0.1.1\",\"blueos.local:127.0.1.1\"]}}"
    },
    {
      "docker": "williangalvani/blueos-extension-proxy",
      "enabled": true,
      "identifier": "williangalvani.blueos-proxy",
      "name": "BlueOS Proxy",
      "permissions": "{\"ExposedPorts\":{},\"HostConfig\":{\"Binds\":[\"/usr/blueos/userdata/blueos-proxy/:/usr/blueos/userdata/blueos-proxy/\"],\"NetworkMode\":\"host\"}}",
      "tag": "$BLUEOS_PROXY_TAG",
      "user_permissions": ""
    }
  ],
  "manifests": []
}
EOF

echo "Default extensions settings configured successfully."
