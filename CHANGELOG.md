# Changelog

## 1.0.9 - 2026-01-18

### Changed

- Updated YAML array format in `settings.yaml`.
    - Updated `:php_error_reporting` value.
- Updated `Vagrantfile` by adding local variables.
    - Modernized path in the `YAML.load_file()` call.
- Replaced `FORWARDED_PORT_80` variable with `HOST_HTTP_PORT` in 3 files.
    - Updated `provision.sh`, `adminer.conf`, `virtualhost.conf` with new variable name.
- Modified the version section of `provision.sh` for the section title and the Apache version output.
- Updated the last section of `README.md`.
- Updated CHANGELOG.

## 1.0.8 - 2025-10-13

### Added

- Added `CHANGELOG.md`

### Changed

- Updated `README.md`

### Fixed

- PHP repositories for Ubuntu 18-04 (Bionic) are no longer available from `packages.sury.org`
    - Removed `sury` PHP repository
    - Reverted to original Ubuntu 18-04 PHP version 7.2
- Updated Adminer to version 5+ plugin code and files

## 1.0.7 - 2023-08-10

## Fixed

- Fixed Ruby variables in `Vagrantfile`

## 1.0.6 - 2023-01-16

## Changed

- Updated Adminer
- Edited `settings.yaml`

## 1.0.5 - 2022-05-06

## Changed

- Moved box name to `settings.yaml`.
- Hard-coded `/vagrant/config` in `provision.sh`.

## 1.0.4 - 2022-04-29

### Added

- Added `:php_error_reporting` to `settings.yaml`.
- Added Ubuntu repo update in `provision.sh`.

## Changed

- Modernized this repo.
- Modified `Vagrantfile`, `provision.sh`.
- Updated PHP to 7.4, MariaDB to 10.5.
- Updated README, `settings.yaml`, `virtualhost.conf`, `adminer.conf`, `bash_aliases`.
- Upgraded to MariaDB 10.6
    - Changed MariaDB repo URLs.

## Fixed

- Fixed Adminer password lock.

## 1.0.3 - 2021-02-06

## Changed

- Updated MariaDB mirror URL. Added `php-yaml` package.

## 1.0.2 - 2020-01-22

## Changed

- Modified Adminer download to 'latest' without having to know the version number in advance.
- Updated README on Adminer.
- Renamed variables.
- Updated provision script.

## 1.0.1 - 2019-11-18

### Added

- Created `bash_aliases`.

### Changed

- Updated provision script.
- Updated README, `.gitignore`, `Vagrantfile`.

## 1.0.0 - 2019-10-10

_First release_
