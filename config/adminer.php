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
include "./adminer-latest.php";
