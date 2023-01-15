timedatectl set-timezone $TIMEZONE

echo '==> Setting time zone to '$(cat /etc/timezone)

echo '==> Updating Ubuntu repositories'

apt-get -q=2 update --fix-missing

echo '==> Installing Linux tools'

cp /vagrant/config/bash_aliases /home/vagrant/.bash_aliases
chown vagrant:vagrant /home/vagrant/.bash_aliases
apt-get -q=2 install software-properties-common bash-completion curl tree zip unzip pv whois &>/dev/null

echo '==> Installing Git and Subversion'

apt-get -q=2 install git subversion subversion-tools &>/dev/null

echo '==> Installing Apache'

apt-get -q=2 install apache2 apache2-utils &>/dev/null
apt-get -q=2 update
cp /vagrant/config/localhost.conf /etc/apache2/conf-available/localhost.conf
cp /vagrant/config/virtualhost.conf /etc/apache2/sites-available/virtualhost.conf
sed -i 's|GUEST_SYNCED_FOLDER|'$GUEST_SYNCED_FOLDER'|' /etc/apache2/sites-available/virtualhost.conf
sed -i 's|FORWARDED_PORT_80|'$FORWARDED_PORT_80'|' /etc/apache2/sites-available/virtualhost.conf
a2enconf localhost &>/dev/null
a2enmod rewrite vhost_alias &>/dev/null
a2ensite virtualhost &>/dev/null

echo '==> Setting MariaDB 10.6 repository'

apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc' &>/dev/null
cp /vagrant/config/MariaDB.list /etc/apt/sources.list.d/MariaDB.list
apt-get -q=2 update

echo '==> Installing MariaDB'

DEBIAN_FRONTEND=noninteractive apt-get -q=2 install mariadb-server &>/dev/null

echo '==> Setting PHP 7.4 repository'

add-apt-repository -y ppa:ondrej/php &>/dev/null
apt-get -q=2 update

echo '==> Installing PHP'

apt-get -q=2 install php7.4 libapache2-mod-php7.4 libphp7.4-embed \
    php7.4-bcmath php7.4-bz2 php7.4-cli php7.4-curl php7.4-fpm php7.4-gd php7.4-imap php7.4-intl php7.4-json \
    php7.4-mbstring php7.4-mysql php7.4-mysqlnd php7.4-opcache php7.4-pgsql php7.4-pspell php7.4-readline \
    php7.4-soap php7.4-sqlite3 php7.4-tidy php7.4-xdebug php7.4-xml php7.4-xmlrpc php7.4-yaml php7.4-zip &>/dev/null
a2dismod mpm_event &>/dev/null
a2enmod mpm_prefork &>/dev/null
a2enmod php7.4 &>/dev/null
cp /vagrant/config/php.ini.htaccess /var/www/.htaccess
PHP_ERROR_REPORTING_INT=$(php -r 'echo '"$PHP_ERROR_REPORTING"';')
sed -i 's|PHP_ERROR_REPORTING|'$PHP_ERROR_REPORTING_INT'|' /var/www/.htaccess

echo '==> Installing Adminer'

if [ ! -d /usr/share/adminer ]; then
    mkdir -p /usr/share/adminer/plugins
    curl -LsS https://www.adminer.org/latest-en.php -o /usr/share/adminer/latest-en.php
    curl -LsS https://raw.githubusercontent.com/vrana/adminer/master/plugins/plugin.php -o /usr/share/adminer/plugins/plugin.php
    curl -LsS https://raw.githubusercontent.com/vrana/adminer/master/plugins/login-password-less.php -o /usr/share/adminer/plugins/login-password-less.php
    curl -LsS https://raw.githubusercontent.com/vrana/adminer/master/plugins/dump-json.php -o /usr/share/adminer/plugins/dump-json.php
    curl -LsS https://raw.githubusercontent.com/vrana/adminer/master/plugins/pretty-json-column.php -o /usr/share/adminer/plugins/pretty-json-column.php
    curl -LsS https://raw.githubusercontent.com/vrana/adminer/master/designs/nicu/adminer.css -o /usr/share/adminer/adminer.css
fi
cp /vagrant/config/adminer.php /usr/share/adminer/adminer.php
cp /vagrant/config/adminer.conf /etc/apache2/conf-available/adminer.conf
sed -i 's|FORWARDED_PORT_80|'$FORWARDED_PORT_80'|' /etc/apache2/conf-available/adminer.conf
a2enconf adminer &>/dev/null

echo '==> Starting Apache'

apache2ctl configtest
service apache2 restart

echo '==> Starting MariaDB'

service mysql restart
mysqladmin -u root password ""

echo '==> Cleaning apt cache'

apt-get -q=2 autoclean
apt-get -q=2 autoremove

echo '==> Versions:'

lsb_release -d | cut -f 2
openssl version
curl --version | head -n1 | cut -d '(' -f 1
svn --version | grep svn,
git --version
apache2 -v | head -n1
mysql -V
php -v | head -n1
python --version 2>/dev/stdout
python3 --version
