# Vagrant box Ubuntu 18.04 LAMP

Make a Vagrant box with Ubuntu 18.04 LAMP stack, plus configure it for development,
plus install Python, Ruby, Rails, Node.js, Codeception, Java, Selenium, headless Chrome browser.

- Host: Linux or Mac.
- Guest: Ubuntu 18.04, Apache 2.4, MariaDB 10.3, PHP 7.2, Git 2.18.

## Goals

- Use a clean Ubuntu 18.04 box available from Bento with 64GB HDD virtual space.
- Leave code and version control files physically outside the VM while virtually accessing them inside the VM.
- Use any GUI tool outside the VM to access data inside the VM.
    - IDEs, browsers, database administration applications, Git clients
- Use `http://localhost:8000` in a browser outside the VM to access Apache inside the VM.
- Use the same SSH keys inside and outside VM.
- Use the same Git config inside and outside VM.
- Have `Vagrantfile` and its provision file be located anywhere on your host machine, independently of your projects location.
- Use `~` as `/home/vagrant` inside the VM for the location of synchronized directories.
    - Disable the default `/vagrant` synchronized to `Vagrantfile`'s location.
- Use Bash for provisioning.
    - Every developer will know Bash; not every developer will know Ansible, Chef and Puppet.
    - You copy/paste the Bash commands if you configured a VirtualBox manually without Vagrant.
- Use MariaDB and Adminer without a password for username `root`.
- Use Apache `.conf` files outside the VM to customize the web server configuration inside the VM.
- Use `rbenv` to install Ruby.
- Use `bundler` to install Rails.

## Prerequisites

### Vagrant and Oracle VM VirtualBox installed

- [VirtualBox 6.0.10](https://www.virtualbox.org/wiki/Downloads)
- [VirtualBox 6.0.10 Extension Pack](https://www.virtualbox.org/wiki/Downloads)
- [VirtualBox Guest Additions](https://www.virtualbox.org/manual/ch04.html#additions-linux)
- [Vagrant 2.2.5](https://www.vagrantup.com/downloads.html)

Look at all VirtualBox downloads [here](https://download.virtualbox.org/virtualbox)

### VirtualBox Guest Additions Vagrant plugin installed

<https://github.com/dotless-de/vagrant-vbguest>

In host terminal:

```bash
vagrant plugin update
vagrant plugin install vagrant-vbguest
```

### SSH keys already set on host machine

In host terminal:

```bash
cat ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub
```

And maybe:

```bash
cat ~/.ssh/authorized_keys
cat ~/.ssh/config
cat ~/.ssh/known_hosts
```

### Git already configured on host machine

In host terminal:

```bash
cat ~/.gitconfig
```

## Start here

In host terminal:

```bash
mkdir -p ~/vm && cd ~/vm
git clone https://github.com/stemar/vagrant-ubuntu-18-04.git ubuntu-18-04
tree -aF --dirsfirst -I ".git" ~/vm
```

```console
/Users/stemar/vm/
└── ubuntu-18-04
    ├── config/
    │   ├── adminer.conf
    │   ├── adminer.php
    │   ├── localhost.conf
    │   ├── php.ini.htaccess
    │   └── virtualhost.conf
    ├── .gitignore
    ├── LICENSE
    ├── README.md
    ├── Vagrantfile
    └── ubuntu-18-04.sh
```

> You can have more than one vagrant dirtree under the `~/vm` directory.

## Main files

### Vagrantfile

On line 1, edit the `projects_path` value with your own path name.
Name it the same name to reduce confusion.
Ex.: if the host machine has `~/projects` a.k.a. `/Users/stemar/projects`,
the guest machine will have `~/projects`, a.k.a. `/home/vagrant/projects`.

```ruby
projects_path = ENV["PROJECTS_PATH"] || "projects"
Vagrant.require_version ">= 2.0.0"
Vagrant.configure("2") do |config|
  config.vm.define "ubuntu-18-04"
  config.vm.box = "bento/ubuntu-18.04" # 64GB HDD
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "3072" # 3GB RAM
    vb.cpus = 1
  end
  # vagrant@ubuntu-18-04
  config.vm.hostname = "ubuntu-18-04"
  # Synchronize projects and vm directories
  config.vm.synced_folder "~/#{projects_path}", "/home/vagrant/#{projects_path}", owner: "vagrant", group: "vagrant"
  config.vm.synced_folder "~/vm", "/home/vagrant/vm", owner: "vagrant", group: "vagrant"
  # Disable default dir sync
  config.vm.synced_folder ".", "/vagrant", disabled: true
  # Apache: http://localhost:8000
  # Puma: `rails server -b 0.0.0.0` => http://localhost:3000
  config.vm.network :forwarded_port, guest: 80, host: 8000    # HTTP
  config.vm.network :forwarded_port, guest: 3306, host: 33060 # MySQL
  config.vm.network :forwarded_port, guest: 3000, host: 3000  # Rails Puma
  config.vm.network :forwarded_port, guest: 4444, host: 4444  # Selenium
  config.vm.network :forwarded_port, guest: 9222, host: 9222  # Chromedriver
  # Copy SSH keys and Git config
  config.vm.provision :file, source: "~/.ssh", destination: "$HOME/.ssh"
  config.vm.provision :file, source: "~/.gitconfig", destination: "$HOME/.gitconfig"
  # Provision bash script
  config.vm.provision :shell, path: "ubuntu-18-04.sh"
end
```

### Provision file ubuntu-18-04.sh

```bash
VM_CONFIG_PATH=/home/vagrant/vm/ubuntu-18-04/config

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

ADMINER_VERSION=4.7.3
if [ ! -d /usr/share/adminer ]; then
    mkdir -p /usr/share/adminer/plugins
    curl -LsS https://github.com/vrana/adminer/releases/download/v$ADMINER_VERSION/adminer-$ADMINER_VERSION.php -o /usr/share/adminer/adminer-$ADMINER_VERSION.php
    curl -LsS https://raw.githubusercontent.com/vrana/adminer/master/plugins/plugin.php -o /usr/share/adminer/plugins/plugin.php
    curl -LsS https://raw.githubusercontent.com/vrana/adminer/master/plugins/login-password-less.php -o /usr/share/adminer/plugins/login-password-less.php
    curl -LsS https://raw.githubusercontent.com/vrana/adminer/master/designs/nicu/adminer.css -o /usr/share/adminer/adminer.css
fi

echo '==> Configuring Apache'

# Localhost
cp $VM_CONFIG_PATH/localhost.conf /etc/apache2/conf-available/localhost.conf
a2enconf localhost

# VirtualHost(s)
cp $VM_CONFIG_PATH/virtualhost.conf /etc/apache2/sites-available/virtualhost.conf
a2ensite virtualhost

# Adminer
cp $VM_CONFIG_PATH/adminer.conf /etc/apache2/conf-available/adminer.conf
a2enconf adminer
cp $VM_CONFIG_PATH/adminer.php /usr/share/adminer/adminer.php
ESCAPED_ADMINER_VERSION=`echo $ADMINER_VERSION | sed 's/\./\\\\./g'`
sed -i 's/ADMINER_VERSION/'$ESCAPED_ADMINER_VERSION'/' /usr/share/adminer/adminer.php

# PHP.ini
cp $VM_CONFIG_PATH/php.ini.htaccess /var/www/.htaccess

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
```

## Config files

### Apache .conf files

#### localhost.conf

I override some `apache2.conf` lines without editing `apache2.conf` itself.

```apache
# Override /etc/apache2/apache2.conf
# /etc/apache2/envvars contains:
# export APACHE_RUN_USER=www-data
# export APACHE_RUN_GROUP=www-data
# /etc/apache2/apache2.conf contains:
# User ${APACHE_RUN_USER}
# Group ${APACHE_RUN_GROUP}
User vagrant
Group vagrant

# Set default http://localhost:8000
ServerName localhost

# Allow .htaccess for all sites
<Directory /var/www>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>
```

#### virtualhost.conf

```apache
# ~/projects
# └── example.com
#     ├── app
#     │   └── ...
#     └── www
#         └── {public files}

# http://example.com.localhost:8000 => VirtualDocumentRoot
<VirtualHost *:80>
    UseCanonicalName Off
    ServerAlias *.localhost
    VirtualDocumentRoot /home/vagrant/projects/%-2+/www
    <Directory /home/vagrant/projects>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    # /var/log/apache2
    ErrorLog ${APACHE_LOG_DIR}/example.com-error.log
    CustomLog ${APACHE_LOG_DIR}/example.com-access.log combined
</VirtualHost>
```

I use [VirtualDocumentRoot](https://httpd.apache.org/docs/2.4/mod/mod_vhost_alias.html)
to access all my domain dirtrees from `~/projects` with `http://example.com.localhost:8000`

```console
~/projects
└── example.com
    ├── app
    │   └── ...
    └── www
        └── {public files}
```

You can create `<VirtualHost *:80>` entries the regular way too for example:

```apache
# http://example.com.localhost:8000 => DocumentRoot
<VirtualHost *:80>
    ServerName example.com.localhost
    DocumentRoot /home/vagrant/example.com/www
    <Directory /home/vagrant/example.com>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    # /var/log/apache2
    ErrorLog ${APACHE_LOG_DIR}/example.com-error.log
    CustomLog ${APACHE_LOG_DIR}/example.com-access.log combined
</VirtualHost>
```

### Adminer files

#### adminer.conf

```apache
# http://localhost:8000/adminer.php
Alias /adminer.php /usr/share/adminer/adminer.php
Alias /adminer.css /usr/share/adminer/adminer.css
<Directory /usr/share/adminer>
    Options FollowSymlinks
    AllowOverride All
    Require all granted
    Allow from 127.0.0.1
</Directory>
```

#### adminer.php

We want `root` with no password in our VM to avoid writing a password zillions of time we access MySQL inside the VM.
Of course, you would have a `root` password on a server but this is a virtual machine hosted locally.

As of version 4.6.3, Adminer is blocking any user with no password.
To allow `root` with no password, we have to create a custom `adminer.php` file.

```php
<?php
// https://www.adminer.org/en/plugins/#use
function adminer_object() {
    include_once "./plugins/plugin.php";
    include_once "./plugins/login-password-less.php";
    class AdminerCustomPlugin extends AdminerPlugin {
        function login($login, $password) {
            return TRUE;
        }
    }
    return new AdminerCustomPlugin(array(
        new AdminerLoginPasswordLess(""),
    ));
}
include "./adminer-ADMINER_VERSION.php";
```

`ADMINER_VERSION` is there to be substituted by a `sed` command in the `ubuntu-18-04.sh` provision script.

### php.ini file

We don't want to edit `php.ini` directly but we want to add a development-related custom set of `php.ini` overrides.

> PHP doesn't allow the loading of a custom `php.ini` file to override its own settings
> ([except when PHP is installed as CGI](http://php.net/manual/en/configuration.file.per-user.php)
> which is not the case here).

We have to do it with `.htaccess` at the `/var/www` level; see [PHP configuration settings](http://php.net/manual/en/configuration.changes.php)

#### php.ini.htaccess

```apache
# http://php.net/manual/en/configuration.changes.php
# http://php.net/manual/en/ini.list.php

# Development environment error settings
php_flag display_startup_errors on
php_flag display_errors on
php_flag html_errors on
php_flag ignore_repeated_errors off
php_flag ignore_repeated_source off
php_flag report_memleaks on
php_flag track_errors on
php_value docref_root 0
php_value docref_ext 0
php_flag log_errors off
php_value log_errors_max_len 0
# E_ALL
# php_value error_reporting -1
# E_ALL & ~E_NOTICE & ~E_DEPRECATED & ~E_STRICT
php_value error_reporting 22519

# Application settings
php_value upload_max_filesize 512M
php_value post_max_size 512M
php_value memory_limit 512M
```

## Provision ubuntu-18-04

In host terminal:

```bash
cd ~/vm/ubuntu-18-04
vagrant up --provision
```

Or if you have a different projects path under your home directory.

```bash
PROJECTS_PATH="Web" vagrant up --provision
```

!! You might see many red line warnings from `apt-get` during provisioning but let the script finish, they are not fatal errors.

### If something goes wrong

In host terminal:

```bash
vagrant halt -f
vagrant destroy -f
vagrant up --provision
```

## Log in ubuntu-18-04

In host terminal:

```bash
vagrant ssh
```

### Prompt inside ubuntu-18-04

In guest terminal:

```console
vagrant@ubuntu-18-04:~$
```

## Checks

### Test `ll` alias and show .bashrc

In guest terminal:

```bash
ll
...
cat ~/.bashrc
```

### Check MariaDB root no password

In guest terminal:

```bash
mysql -u root
MariaDB [(none)]> SHOW DATABASES; quit;
```

## Check Apache

In guest terminal:

```bash
cat /etc/hosts
cat /etc/apache2/apache2.conf
cat /etc/apache2/envvars
ll /etc/apache2/conf-available
ll /etc/apache2/conf-enabled
ll /etc/apache2/sites-available
ll /etc/apache2/sites-enabled
cat /etc/apache2/conf-available/localhost.conf
cat /etc/apache2/sites-available/virtualhost.conf
cat /etc/apache2/conf-available/adminer.conf
apachectl -V
apachectl configtest
curl -I localhost
```

Result:

```http
HTTP/1.1 200 OK
...
```

### In host browser

```input
http://localhost:8000
```

You see the "Apache2 Ubuntu Default Page".

```input
http://example.com.localhost:8000
```

You see the `example.com` home page.

## Check Adminer

### In guest terminal

```bash
curl -I localhost/adminer.php
```

Result:

```http
HTTP/1.1 200 OK
...
```

### In host browser

```input
http://localhost:8000/adminer.php
```

- Username: `root`
- Password: leave empty

---

## References

- Vagrant: <https://www.vagrantup.com>
- Vagrant troubleshooting: <https://www.mediawiki.org/wiki/MediaWiki-Vagrant#Troubleshooting_startup>
- Oracle VirtualBox: <https://www.virtualbox.org/wiki/Downloads>
- Oracle VirtualBox Guest Additions: <https://www.virtualbox.org/manual/ch04.html>
- Ubuntu: <https://www.ubuntu.com>
- Bento box: <https://app.vagrantup.com/bento/boxes/ubuntu-18.04>
- Bento GitHub: <https://github.com/chef/bento>
- <https://www.howtoforge.com/tutorial/install-apache-with-php-and-mysql-on-ubuntu-18-04-lamp>
- <https://linuxize.com/post/how-to-install-mariadb-on-ubuntu-18-04>
