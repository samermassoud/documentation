#!/bin/sh

LC_BRANCH=v1
GITHUB_USER=eduvpn
BASE_DIR=${HOME}/Projects/LC-${LC_BRANCH}

mkdir -p "${BASE_DIR}"
cd "${BASE_DIR}" || exit

# clone repositories (read-only)
git clone -b ${LC_BRANCH} https://github.com/${GITHUB_USER}/vpn-lib-common.git
git clone -b ${LC_BRANCH} https://github.com/${GITHUB_USER}/vpn-user-portal.git
git clone -b ${LC_BRANCH} https://github.com/${GITHUB_USER}/vpn-admin-portal.git
git clone -b ${LC_BRANCH} https://github.com/${GITHUB_USER}/vpn-server-api.git
git clone -b ${LC_BRANCH} https://github.com/${GITHUB_USER}/vpn-server-node.git
git clone -b ${LC_BRANCH} https://github.com/${GITHUB_USER}/documentation.git

# clone all repositories (read/write, your own "forks")
#git clone -b ${LC_BRANCH} git@github.com:${GITHUB_USER}/vpn-lib-common.git
#git clone -b ${LC_BRANCH} git@github.com:${GITHUB_USER}/vpn-user-portal.git
#git clone -b ${LC_BRANCH} git@github.com:${GITHUB_USER}/vpn-admin-portal.git
#git clone -b ${LC_BRANCH} git@github.com:${GITHUB_USER}/vpn-server-api.git
#git clone -b ${LC_BRANCH} git@github.com:${GITHUB_USER}/vpn-server-node.git
#git clone -b ${LC_BRANCH} git@github.com:${GITHUB_USER}/documentation.git

# vpn-server-api
cd "${BASE_DIR}/vpn-server-api" || exit
composer update
mkdir config/default
cp config/config.php.example config/default/config.php
mkdir -p data/default
php bin/init.php

# vpn-user-portal
cd "${BASE_DIR}/vpn-user-portal" || exit
composer update
mkdir config/default
cp config/config.php.example config/default/config.php
mkdir -p data/default
php bin/init.php
php bin/add-user.php --user foo --pass bar
sed -i "s/'secureCookie' => true/'secureCookie' => false/" config/default/config.php
sed -i "s/'enableTemplateCache' => true/'enableTemplateCache' => false/" config/default/config.php
sed -i "s|'apiUri' => 'http://localhost/vpn-server-api/api.php'|'apiUri' => 'http://localhost:8008/api.php'|" config/default/config.php

# vpn-admin-portal
cd "${BASE_DIR}/vpn-admin-portal" || exit
composer update
mkdir config/default
cp config/config.php.example config/default/config.php
mkdir -p data/default
php bin/add-user.php --user foo --pass bar
sed -i "s/'secureCookie' => true/'secureCookie' => false/" config/default/config.php
sed -i "s/'enableTemplateCache' => true/'enableTemplateCache' => false/" config/default/config.php
sed -i "s|'apiUri' => 'http://localhost/vpn-server-api/api.php'|'apiUri' => 'http://localhost:8008/api.php'|" config/default/config.php

# vpn-server-node
cd "${BASE_DIR}/vpn-server-node" || exit
composer update
mkdir config/default
cp config/config.php.example config/default/config.php
cp config/firewall.php.example config/firewall.php
mkdir -p data/default
mkdir openvpn-config
sed -i "s|'apiUri' => 'http://localhost/vpn-server-api/api.php'|'apiUri' => 'http://localhost:8008/api.php'|" config/default/config.php

# launch script
cat << 'EOF' | tee "${BASE_DIR}/launch.sh" > /dev/null
#!/bin/sh
(
    cd vpn-server-api || exit
    VPN_INSTANCE_ID=default php -S localhost:8008 -t web &
)
(
    cd vpn-user-portal || exit
    VPN_INSTANCE_ID=default php -S localhost:8082 -t web &
)
(
    cd vpn-admin-portal || exit
    VPN_INSTANCE_ID=default php -S localhost:8083 -t web &
)
EOF
chmod +x "${BASE_DIR}/launch.sh"
