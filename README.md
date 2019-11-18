# Vagrant box Ubuntu 18.04 LAMP

Make a Vagrant box with Ubuntu 18.04 LAMP stack, plus configure it for development,
plus install Python, Ruby, Rails, Node.js, Codeception, Java, Selenium, headless Chrome browser.

- Host: Linux or Mac.
- Guest: Ubuntu 18.04, Apache 2.4, MariaDB 10.3, PHP 7.2, Git 2.18.

## Summary

In host terminal:

```bash
mkdir -p ~/vm && cd $_
git clone https://github.com/stemar/vagrant-ubuntu-18-04.git ubuntu-18-04
cd ~/vm/ubuntu-18-04
vagrant up --provision
vagrant ssh
```

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
    - You could copy/paste the Bash commands if you configured a VirtualBox manually without Vagrant.
- Use MariaDB and Adminer without a password for username `root`.
- Use Apache `.conf` files outside the VM to customize the web server configuration inside the VM.

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
mkdir -p ~/vm && cd $_
git clone https://github.com/stemar/vagrant-ubuntu-18-04.git ubuntu-18-04
```

> You can have more than one vagrant dirtree under the `~/vm` directory.  
> Ex.: `git clone https://github.com/stemar/vagrant-centos-7-6.git centos-7-6`

### Separate VMs dirtree

Vagrant supports the definition of [multiple VMs](https://www.vagrantup.com/docs/multi-machine) inside one `Vagrantfile`,
but if I separate my VMs by LAMP stack in a dirtree, I can run, maintain and troubleshoot them independently.

- I can have a smaller, focused `Vagrantfile` for each VM.
- I can have LAMP-specific `config` files to help the provision file.
- `.vagrant` is created independently within each VM directory.
- I can open separate tabs in my terminal, `cd` into separate VM dirtrees and `vagrant up`/`vagrant halt`
  without having to write the machine name: `vagrant up ubuntu-18-04`/`vagrant halt ubuntu-18-04`
- `vagrant global-status` still works as intended to see all VMs on the host machine.
- I change the HTTP and MySQL ports in `Vagrantfile` to avoid collisions and Vagrant errors at provisioning.

### adminer.php

We want `root` with no password in our VM to avoid writing a password zillions of time we access MySQL inside the VM.
Of course, you would have a `root` password on a server but this is a virtual machine hosted locally.

As of version 4.6.3, Adminer is blocking any user with no password.
To allow `root` with no password, `config/adminer.php` is created.

> The constant`ADMINER_VERSION` will be substituted by a `sed` command in the `ubuntu-18-04.sh` provision script.

### php.ini file

We don't want to edit `php.ini` directly but we want to add a development-related custom set of `php.ini` overrides.

> PHP doesn't allow the loading of a custom `php.ini` file to override its own settings
> ([except when PHP is installed as CGI](http://php.net/manual/en/configuration.file.per-user.php)
> which is not the case here).

We have to do it with `.htaccess` at the `/var/www` level;
see [PHP configuration settings](http://php.net/manual/en/configuration.changes.php)

## Provision ubuntu-18-04

> You will see many red line warnings from `apt-get` during provisioning but let the script finish,
> most of them are not fatal errors.

You can prepend the `vagrant up` command with these environment variables or
you can edit `Vagrantfile`.

### PROJECTS_DIR

Add the environment variable `PROJECTS_DIR` with your own path name under your home directory.
Name it the same name to reduce confusion.
Ex.: if the host machine has `~/projects` a.k.a. `/Users/stemar/projects`,
the guest machine will have `~/projects`, a.k.a. `/home/vagrant/projects`.

In host terminal:

```bash
cd ~/vm/ubuntu-18-04
PROJECTS_DIR=projects vagrant up --provision
```

### PORT_80

Add the environment variable `PORT_80` with a port number to redirect to.
Ex.: redirect port 80 to port 8080.

In host terminal:

```bash
cd ~/vm/ubuntu-18-04
PORT_80=8080 vagrant up --provision
```

### PORT_3306

Add the environment variable `PORT_3306` with a port number to redirect to.
Ex.: redirect port 3306 to port 33061.

In host terminal:

```bash
cd ~/vm/ubuntu-18-04
PORT_80=8080 PORT_3306=33061 vagrant up --provision
```

### ADMINER_VERSION

Add the environment variable `ADMINER_VERSION` with a version number.
Ex.: use version 4.7.4

In host terminal:

```bash
cd ~/vm/ubuntu-18-04
ADMINER_VERSION=4.7.4 vagrant up --provision
```

### If you get this error after VirtualBox Guest Additions plugin changed versions

```
Vagrant was unable to mount VirtualBox shared folders. This is usually
because the filesystem "vboxsf" is not available. This filesystem is
made available via the VirtualBox Guest Additions and kernel module.
Please verify that these guest additions are properly installed in the
guest. This is not a bug in Vagrant and is usually caused by a faulty
Vagrant box. For context, the command attempted was:

mount -t vboxsf -o uid=1000,gid=1000 home_vagrant_vm /home/vagrant/vm

The error output from the command was:

/sbin/mount.vboxsf: mounting failed with the error: No such device
```

Halt the box and redo up

```bash
vagrant halt
PROJECTS_DIR=projects vagrant up --provision
```

### If something goes wrong

In host terminal:

```bash
vagrant halt -f
OR
vagrant destroy -f
AND
PROJECTS_DIR=projects vagrant up --provision
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

### Check Apache

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

In host browser:

```input
http://localhost:8000
```

You see the "Apache2 Ubuntu Default Page".

### Check your domain

Ex.: Replace `example.com` with your domain and the port number with your custom redirect number.

In host browser:

```input
http://example.com.localhost:8000
```

You see the home page.

### Check Adminer

In guest terminal:

```bash
curl -I localhost/adminer.php
```

Result:

```http
HTTP/1.1 200 OK
...
```

In host browser:

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
