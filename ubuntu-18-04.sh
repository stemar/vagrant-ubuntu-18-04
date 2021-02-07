echo '==> Setting time zone'

timedatectl set-timezone Canada/Pacific
cat /etc/timezone

echo '==> Installing Linux tools'

apt-get -qq update
apt-get -qq install bash-completion curl tree zip unzip pv whois
cp $CONFIG_PATH/bash_aliases /home/vagrant/.bash_aliases
chown vagrant:vagrant /home/vagrant/.bash_aliases

echo '==> Installing Git'

apt-get -qq install git git-man

echo '==> Installing Apache'

apt-get -qq install apache2

echo '==> Setting MariaDB 10.3 repository'

# https://downloads.mariadb.org/mariadb/repositories/#mirror=digitalocean-sfo&version=10.3
apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://sfo1.mirrors.digitalocean.com/mariadb/repo/10.3/ubuntu bionic main'
apt-get -qq update

echo '==> Installing MariaDB'

DEBIAN_FRONTEND=noninteractive apt-get -qq install mariadb-server

echo '==> Installing PHP'

apt-get -qq install php7.2 libapache2-mod-php7.2 libphp7.2-embed \
    php7.2-bcmath php7.2-bz2 php7.2-cli php7.2-curl php7.2-fpm php7.2-gd php7.2-imap php7.2-intl php7.2-json \
    php7.2-mbstring php7.2-mysql php7.2-mysqlnd php7.2-opcache php7.2-pgsql php7.2-pspell php7.2-readline \
    php7.2-soap php7.2-sqlite3 php7.2-tidy php7.2-xdebug php7.2-xml php7.2-xmlrpc php7.2-yaml php7.2-zip

echo '==> Installing Adminer'

if [ ! -d /usr/share/adminer ]; then
    mkdir -p /usr/share/adminer/plugins
    curl -LsS https://github.com/vrana/adminer/releases/download/v$ADMINER_VERSION/adminer-$ADMINER_VERSION.php -o /usr/share/adminer/adminer-$ADMINER_VERSION.php
    curl -LsS https://raw.githubusercontent.com/vrana/adminer/master/plugins/plugin.php -o /usr/share/adminer/plugins/plugin.php
    curl -LsS https://raw.githubusercontent.com/vrana/adminer/master/plugins/login-password-less.php -o /usr/share/adminer/plugins/login-password-less.php
    curl -LsS https://raw.githubusercontent.com/vrana/adminer/master/designs/nicu/adminer.css -o /usr/share/adminer/adminer.css
fi

echo '==> Configuring Apache'

# Localhost
cp $CONFIG_PATH/localhost.conf /etc/apache2/conf-available/localhost.conf
sed -i 's#PORT_80#'$PORT_80'#' /etc/apache2/conf-available/localhost.conf
a2enconf localhost

# VirtualHost(s)
cp $CONFIG_PATH/virtualhost.conf /etc/apache2/sites-available/virtualhost.conf
sed -i 's#PROJECTS_DIR#'$PROJECTS_DIR'#' /etc/apache2/sites-available/virtualhost.conf
sed -i 's#PORT_80#'$PORT_80'#' /etc/apache2/sites-available/virtualhost.conf
a2ensite virtualhost

# Adminer
cp $CONFIG_PATH/adminer.conf /etc/apache2/conf-available/adminer.conf
sed -i 's#PORT_80#'$PORT_80'#' /etc/apache2/conf-available/adminer.conf
a2enconf adminer
cp $CONFIG_PATH/adminer.php /usr/share/adminer/adminer.php
ESCAPED_ADMINER_VERSION=`echo $ADMINER_VERSION | sed 's/\./\\\\./g'`
sed -i 's#ADMINER_VERSION#'$ESCAPED_ADMINER_VERSION'#' /usr/share/adminer/adminer.php

# PHP.ini
cp $CONFIG_PATH/php.ini.htaccess /var/www/.htaccess

# Modules
a2enmod rewrite vhost_alias
a2dismod mpm_event && a2enmod mpm_prefork && a2enmod php7.2

echo '==> Starting Apache'

apache2ctl configtest
service apache2 restart

echo '==> Starting MariaDB'

service mysql restart

echo '==> Cleaning apt cache'

apt-get -qq autoclean
apt-get -qq autoremove
apt-get -qq clean

echo '==> Versions:'

lsb_release -a
echo $(curl --version | head -n1)
echo $(git --version)
echo $(apache2 -v | head -n1)
echo $(mysql -V)
echo $(php -v | head -n1)
echo $(python --version)
echo $(python3 --version)
echo Adminer $ADMINER_VERSION
