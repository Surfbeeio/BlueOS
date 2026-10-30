#!/usr/bin/env bash

# Versions are pinned: newer SonarView releases broke the dual Omniscan 3D setup that works on 1.14.83

SONARVIEW_TAG="1.14.83"
BLUEOS_PROXY_TAG="v1.0.6"

# Images pulling

docker pull "nicknothom/sonarview:$SONARVIEW_TAG"
docker pull "williangalvani/blueos-extension-proxy:$BLUEOS_PROXY_TAG"

# Nexus Plus isn't on a registry, install.sh loads it from the archive CI embeds when there is one
NEXUS_EXTENSION=""
if docker image inspect nexus-plus:dev > /dev/null 2>&1; then
  NEXUS_EXTENSION=$(cat <<'EOF'
,
    {
      "docker": "nexus-plus",
      "enabled": true,
      "identifier": "io.surfbee.nexus-plus",
      "name": "Nexus Plus",
      "permissions": "{\"ExposedPorts\": {\"80/tcp\": {}, \"6842/udp\": {}, \"6404/tcp\": {}}, \"HostConfig\": {\"Privileged\": true, \"Binds\": [\"/dev:/dev:rw\", \"/boot/firmware/overlays:/boot/firmware/overlays:ro\", \"/sys/kernel/config:/sys/kernel/config:rw\", \"/usr/blueos/userdata/nexus:/userdata:rw\", \"/boot/firmware:/boot/firmware:rw\"], \"ExtraHosts\": [\"host.docker.internal:host-gateway\"], \"PortBindings\": {\"80/tcp\": [{\"HostPort\": \"\"}], \"6842/udp\": [{\"HostPort\": \"6842/udp\"}], \"6404/tcp\": [{\"HostPort\": \"6404/tcp\"}]}}}",
      "tag": "dev",
      "user_permissions": ""
    }
EOF
)
else
  echo "Nexus Plus image not found, leaving it out of the default extensions."
fi

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
    }${NEXUS_EXTENSION}
  ],
  "manifests": []
}
EOF

echo "Default extensions settings configured successfully."
