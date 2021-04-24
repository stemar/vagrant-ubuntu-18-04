echo '==> Setting time zone'

timedatectl set-timezone Canada/Pacific
cat /etc/timezone

echo '==> Installing Linux tools'

cp $VM_CONFIG_PATH/bash_aliases /home/vagrant/.bash_aliases
chown vagrant:vagrant /home/vagrant/.bash_aliases
apt-get -q=2 install software-properties-common bash-completion curl tree zip unzip pv whois > /dev/null 2>&1

echo '==> Installing Git'

apt-get -q=2 install git git-man

echo '==> Installing Apache'

apt-get -q=2 install apache2 apache2-utils > /dev/null 2>&1
apt-get -q=2 update
cp $VM_CONFIG_PATH/localhost.conf /etc/apache2/conf-available/localhost.conf
cp $VM_CONFIG_PATH/virtualhost.conf /etc/apache2/sites-available/virtualhost.conf
sed -i 's|GUEST_SYNCED_FOLDER|'$GUEST_SYNCED_FOLDER'|' /etc/apache2/sites-available/virtualhost.conf
sed -i 's|FORWARDED_PORT_80|'$FORWARDED_PORT_80'|' /etc/apache2/sites-available/virtualhost.conf
a2enconf localhost > /dev/null 2>&1
a2enmod rewrite vhost_alias > /dev/null 2>&1
a2ensite virtualhost > /dev/null 2>&1

echo '==> Installing Subversion'

apt-get -q=2 install subversion subversion-tools > /dev/null 2>&1

echo '==> Setting MariaDB 10.5 repository'

apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc' > /dev/null 2>&1
cp $VM_CONFIG_PATH/MariaDB.list /etc/apt/sources.list.d/MariaDB.list
apt-get -q=2 update

echo '==> Installing MariaDB'

DEBIAN_FRONTEND=noninteractive apt-get -q=2 install mariadb-server > /dev/null 2>&1

echo '==> Setting PHP 7.4 repository'

add-apt-repository -y ppa:ondrej/php > /dev/null 2>&1
apt-get -q=2 update

echo '==> Installing PHP'

apt-get -q=2 install php7.4 libapache2-mod-php7.4 libphp7.4-embed \
    php7.4-bcmath php7.4-bz2 php7.4-cli php7.4-curl php7.4-fpm php7.4-gd php7.4-imap php7.4-intl php7.4-json \
    php7.4-mbstring php7.4-mysql php7.4-mysqlnd php7.4-opcache php7.4-pgsql php7.4-pspell php7.4-readline \
    php7.4-soap php7.4-sqlite3 php7.4-tidy php7.4-xdebug php7.4-xml php7.4-xmlrpc php7.4-yaml php7.4-zip > /dev/null 2>&1
cp $VM_CONFIG_PATH/php.ini.htaccess /var/www/.htaccess
a2dismod mpm_event > /dev/null 2>&1
a2enmod mpm_prefork > /dev/null 2>&1
a2enmod php7.4 > /dev/null 2>&1

echo '==> Installing Adminer'

if [ ! -d /usr/share/adminer ]; then
    mkdir -p /usr/share/adminer
    curl -LsS https://www.adminer.org/latest-en.php -o /usr/share/adminer/adminer.php
    sed -i 's|login($we,$F){if($F=="")return|login($we,$F){if(true)|' /usr/share/adminer/adminer.php
    curl -LsS https://raw.githubusercontent.com/vrana/adminer/master/designs/nicu/adminer.css -o /usr/share/adminer/adminer.css
fi
cp $VM_CONFIG_PATH/adminer.conf /etc/apache2/conf-available/adminer.conf
sed -i 's|FORWARDED_PORT_80|'$FORWARDED_PORT_80'|' /etc/apache2/conf-available/adminer.conf
a2enconf adminer > /dev/null 2>&1

echo '==> Starting Apache'

apache2ctl configtest
service apache2 restart

echo '==> Starting MariaDB'

service mysql restart
mysqladmin -u root password ""

echo '==> Cleaning apt cache'

apt-get -q=2 autoclean
apt-get -q=2 autoremove
apt-get -q=2 clean

echo '==> Versions:'

lsb_release -d
echo $(openssl version)
echo $(curl --version | head -n1)
echo $(svn --version | grep svn,)
echo $(git --version)
echo $(apache2 -v | head -n1)
echo $(mysql -V)
echo $(php -v | head -n1)
echo $(python --version)
echo $(python3 --version)
