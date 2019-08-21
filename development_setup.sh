#!/bin/sh

LC_BRANCH=v2
GITHUB_USER=eduvpn
BASE_DIR=${HOME}/Projects/LC-${LC_BRANCH}

mkdir -p "${BASE_DIR}"
cd "${BASE_DIR}" || exit

# clone repositories (read-only)
git clone -b ${LC_BRANCH} https://github.com/${GITHUB_USER}/vpn-lib-common.git
git clone -b ${LC_BRANCH} https://github.com/${GITHUB_USER}/vpn-user-portal.git
git clone -b ${LC_BRANCH} https://github.com/${GITHUB_USER}/vpn-server-api.git
git clone -b ${LC_BRANCH} https://github.com/${GITHUB_USER}/vpn-server-node.git
git clone -b ${LC_BRANCH} https://github.com/${GITHUB_USER}/documentation.git
git clone -b master       https://github.com/fkooman/vpn-ca.git

# clone all repositories (read/write, your own "forks")
#git clone -b ${LC_BRANCH} git@github.com:${GITHUB_USER}/vpn-lib-common.git
#git clone -b ${LC_BRANCH} git@github.com:${GITHUB_USER}/vpn-user-portal.git
#git clone -b ${LC_BRANCH} git@github.com:${GITHUB_USER}/vpn-server-api.git
#git clone -b ${LC_BRANCH} git@github.com:${GITHUB_USER}/vpn-server-node.git
#git clone -b ${LC_BRANCH} git@github.com:${GITHUB_USER}/documentation.git
#git clone -b master       git@github.com:fkooman/vpn-ca.git

# vpn-user-portal
cd "${BASE_DIR}/vpn-user-portal" || exit
mkdir -p data
composer update

cat << 'EOF' > config/config.php
<?php
$baseConfig = include __DIR__.'/config.php.example';
$localConfig = [
    'secureCookie' => false,
    'apiUri' => 'http://localhost:8008/api.php',
];
return array_merge($baseConfig, $localConfig);
EOF

php bin/init.php
php bin/generate-oauth-key.php
php bin/add-user.php --user foo   --pass bar
php bin/add-user.php --user admin --pass secret

# vpn-ca
cd "${BASE_DIR}/vpn-ca" || exit
go build -o _bin/vpn-ca vpn-ca/*.go

# vpn-server-api
cd "${BASE_DIR}/vpn-server-api" || exit
mkdir -p data
composer update

cat << EOF > config/config.php
<?php
\$baseConfig = include __DIR__.'/config.php.example';
\$localConfig = [
    'vpnCaPath' => '${BASE_DIR}/vpn-ca/_bin/vpn-ca',
];
return array_merge(\$baseConfig, \$localConfig);
EOF

php bin/init.php

# vpn-server-node
cd "${BASE_DIR}/vpn-server-node" || exit
mkdir -p data openvpn-config
composer update
cp config/firewall.php.example config/firewall.php
cat << 'EOF' > config/config.php
<?php
$baseConfig = include __DIR__.'/config.php.example';
$localConfig = [
    'apiUri' => 'http://localhost:8008/api.php',
];
return array_merge($baseConfig, $localConfig);
EOF

# launch script
cat << 'EOF' | tee "${BASE_DIR}/launch.sh" > /dev/null
#!/bin/sh
(
    cd vpn-server-api || exit
    php -S localhost:8008 -t web &
)
(
    cd vpn-user-portal || exit
    php -S localhost:8082 -t web &
)
EOF
chmod +x "${BASE_DIR}/launch.sh"
