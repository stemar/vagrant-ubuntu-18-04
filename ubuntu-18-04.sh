echo '==> Setting time zone'

timedatectl set-timezone Canada/Pacific
cat /etc/timezone

echo '==> Installing Linux tools'

apt-get -qq update
apt-get -qq install bash-completion
apt-get -qq install curl tree zip unzip pv whois
echo 'alias ll="ls -lAFh"
' | tee /home/vagrant/.bash_aliases > /dev/null
chown vagrant:vagrant /home/vagrant/.bash_aliases

echo '==> Installing Git'

apt-get -qq install git git-man

echo '==> Installing Apache'

apt-get -qq install apache2

echo '==> Setting MariaDB 10.3 repository'

apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://ftp.utexas.edu/mariadb/repo/10.3/ubuntu bionic main'
apt-get -qq update

echo '==> Installing MariaDB'

DEBIAN_FRONTEND=noninteractive apt-get -qq install mariadb-server

echo '==> Installing PHP'

apt-get -qq install php7.2 libapache2-mod-php7.2 libphp7.2-embed \
    php7.2-bcmath php7.2-bz2 php7.2-cli php7.2-curl php7.2-fpm php7.2-gd php7.2-imap php7.2-intl php7.2-json \
    php7.2-mbstring php7.2-mysql php7.2-mysqlnd php7.2-opcache php7.2-pgsql php7.2-pspell php7.2-readline \
    php7.2-soap php7.2-sqlite3 php7.2-tidy php7.2-xdebug php7.2-xml php7.2-xmlrpc php7.2-zip

echo '==> Installing Composer (globally)'

if [ ! -f /usr/local/bin/composer ]; then
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --quiet
fi

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
sed -i 's#PROJECTS_PATH#'$PROJECTS_PATH'#' /etc/apache2/sites-available/virtualhost.conf
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

echo '==> Installing Codeception (globally)'

if [ ! -f /usr/local/bin/codecept ]; then
    curl -LsS https://codeception.com/codecept.phar -o /usr/local/bin/codecept
    chmod a+x /usr/local/bin/codecept
fi

echo '==> Installing Java JRE'

apt-get -qq install default-jdk
apt-get -qq install --fix-broken

echo '==> Installing Google Chrome'

if ! grep -qxF 'deb http://dl.google.com/linux/chrome/deb/ stable main' /etc/apt/sources.list; then
    echo 'deb http://dl.google.com/linux/chrome/deb/ stable main' | tee -a /etc/apt/sources.list > /dev/null
    wget -qO- --no-hsts "https://dl-ssl.google.com/linux/linux_signing_key.pub" | apt-key add -
    apt-get -qq update
    apt-get -qq install google-chrome-stable
fi

echo '==> Installing Google XVFB'

apt-get -qq install xvfb
apt-get -qq install --fix-broken

echo '==> Installing chromedriver'

CHROMEDRIVER_VERSION=2.38
if [ ! -f /usr/local/bin/chromedriver ]; then
    curl -LsS https://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip -o /usr/local/bin/chromedriver.zip
    unzip -qq /usr/local/bin/chromedriver.zip -d /usr/local/bin
    chown vagrant:vagrant /usr/local/bin/chromedriver
    rm /usr/local/bin/chromedriver.zip
fi

echo '==> Installing geckodriver'

GECKODRIVER_VERSION=v0.20.1
if [ ! -f /usr/local/bin/geckodriver ]; then
    curl -LsS https://github.com/mozilla/geckodriver/releases/download/$GECKODRIVER_VERSION/geckodriver-$GECKODRIVER_VERSION-linux64.tar.gz -o /usr/local/bin/geckodriver.tar.gz
    tar -xzf /usr/local/bin/geckodriver.tar.gz -C /usr/local/bin
    chown vagrant:vagrant /usr/local/bin/geckodriver
    rm /usr/local/bin/geckodriver.tar.gz
fi

echo '==> Installing Selenium'

SELENIUM_VERSION=3.12
if [ ! -f /usr/local/bin/selenium-server-standalone.jar ]; then
    curl -LsS https://selenium-release.storage.googleapis.com/$SELENIUM_VERSION/selenium-server-standalone-$SELENIUM_VERSION.0.jar -o /usr/local/bin/selenium-server-standalone.jar
    chown vagrant:vagrant /usr/local/bin/selenium-server-standalone.jar
fi

echo '==> Installing rbenv'

apt-get -qq install autoconf bison build-essential \
    libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm5 libgdbm-dev
if [ ! -d /home/vagrant/.rbenv ]; then
    git clone -q https://github.com/rbenv/rbenv.git /home/vagrant/.rbenv
fi
if ! grep -q 'RBENV_ROOT=' /home/vagrant/.bashrc; then
   echo '
# Make rbenv load automatically
export RBENV_ROOT="${HOME}/.rbenv"
export PATH="${RBENV_ROOT}/bin:${PATH}"
eval "$(rbenv init -)"
' | tee -a /home/vagrant/.bashrc > /dev/null
fi
export RBENV_ROOT="/home/vagrant/.rbenv"
if ! grep -q "$RBENV_ROOT" <<< "$PATH"; then
    export PATH="${RBENV_ROOT}/bin:${PATH}"
fi
eval "$(rbenv init -)"
if [ ! -d /home/vagrant/.rbenv/plugins/ruby-build ]; then
    git clone -q https://github.com/rbenv/ruby-build.git /home/vagrant/.rbenv/plugins/ruby-build
fi
chown -R vagrant:vagrant /home/vagrant/.rbenv

echo '==> Installing Ruby'

LATEST_RUBY_VERSION=$(rbenv install -l | grep -v - | tail -1)
rbenv install -s $LATEST_RUBY_VERSION
rbenv global $LATEST_RUBY_VERSION
echo "gem: --no-document" | tee /home/vagrant/.gemrc > /dev/null
chown -R vagrant:vagrant /home/vagrant/.gemrc

echo '==> Installing Bundler'

gem install bundler -N -q --no-force

echo '==> Installing Rails'

gem install rails -N -q --no-force
bundle install
rbenv rehash

echo '==> Installing Python 3'

apt-get -qq install python3-venv python3-pip

echo '==> Installing npm, node.js & Grunt'

apt-get -qq install npm
npm list grunt-cli || npm install -g grunt-cli

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
echo Adminer $ADMINER_VERSION
echo $(composer -V)
echo $(codecept -V)
echo geckodriver $GECKODRIVER_VERSION
echo chromedriver $CHROMEDRIVER_VERSION
echo selenium-server-standalone $SELENIUM_VERSION
echo $(rbenv -v)
echo $(ruby -v)
echo gem $(gem -v)
echo $(bundler -v)
echo $(rails -v)
echo node.js $(nodejs -v)
echo npm $(npm -v)
