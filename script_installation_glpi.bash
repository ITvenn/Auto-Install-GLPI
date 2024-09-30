#!/bin/bash

# --------------------------------------------------------------------------------
# Auteur : HAMEL Vincent
#
# Description :
# Script d'installation' automatique de GLPI et de la version souhaitée.
#
# --------------------------------------------------------------------------------

# Récuperation du chemin ou est executer le script
chemin=$(pwd);



# Choix de la version souhaité
echo -n "Veuillez entrer le numero de version GLPI souhaité dans le format suivant X.X.X"
read version
echo
echo "Voulez-vous vraiment installer la version ${version} de GLPI ? (o/n)"
read reponse
if [ "$reponse" = "o" ]; then
    echo "Installation de GLPI version ${version}..."

    # Installation serveur web APACHE
    echo "Installation d'Apache"
    apt update
    apt install apache2 -y
    rm /etc/apache2/sites-enabled/000-default.conf
    rm /etc/apache2/sites-available/000-default.conf
    echo -n "Veuillez entrer l'adresse IP de votre serveur dans le format suivant : X.X.X.X"
    read ip_server
    touch /etc/apache2/sites-enabled/000-default.conf
    cat <<EOF >> /etc/apache2/sites-enabled/000-default.conf
    <VirtualHost *:80>
        # The ServerName directive sets the request scheme, hostname and port that
        # the server uses to identify itself. This is used when creating
        # redirection URLs. In the context of virtual hosts, the ServerName
        # specifies what hostname must appear in the request's Host: header to
        # match this virtual host. For the default virtual host (this file) this
        # value is not decisive as it is used as a last resort host regardless.
        # However, you must set it for any further virtual host explicitly.
        #ServerName www.example.com
        ServerAlias $ip_server
        #ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html/glpi/public
        #Alias "/glpi" "/var/www/html/glpi/public"
        # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
        # error, crit, alert, emerg.
        # It is also possible to configure the loglevel for particular
        # modules, e.g.
        #LogLevel info ssl:warn

        ErrorLog \${APACHE_LOG_DIR}/error.log
        CustomLog \${APACHE_LOG_DIR}/access.log combined
        <Directory /var/www/html/glpi/public>
            Require all granted
            RewriteEngine On
            RewriteCond %{REQUEST_FILENAME} !-f
            RewriteRule ^(.*)$ index.php [QSA,L]
        </Directory>

        <FilesMatch \.php$>
            SetHandler "proxy:unix:/run/php/php8.2-fpm.sock|fcgi://localhost/"
        </FilesMatch>
        # For most configuration files from conf-available/, which are
        # enabled or disabled at a global level, it is possible to
        # include a line for only one particular virtual host. For example the
        # following line enables the CGI configuration for this host only
        # after it has been globally disabled with "a2disconf".
        #Include conf-available/serve-cgi-bin.conf
    </VirtualHost>
EOF
    cp /etc/apache2/sites-enabled/000-default.conf /etc/apache2/sites-available/ && echo "Installation d'Apache réussi !" || { echo -e "\E[31mErreur : échec d'installation d'Apache.\E[0m"; exit 1; }

    # Installation de PHP et des dépandances
    apt install php -y
    apt install php8.2-fpm -y
    apt install php-xml php-common php-json php-mysql php-mbstring php-curl php-gd php-intl php-zip php-bz2 php-imap php-apcu -y && echo "Installation de php réussi !" || { echo -e "\E[31mErreur : échec d'installation de php.\E[0m"; exit 1; }
    echo "Voulez-vous installer php-ldap pour activer par la suite la synchronisation ldap ? (o/n)"
    read reponse_ldap
    if [ "$reponse_ldap" = "o" ]; then
        apt install php-ldap -y && echo "Installation de php-ldap réussi !" || { echo -e "\E[31mErreur : échec d'installation de php-ldap.\E[0m"; exit 1; }
    fi
    
    # Installation de Mariadb
    apt install mariadb-server -y
    echo "Indiquer un nouveau mot de passe root de la base de données"
    read NEW_ROOT_PASSWORD
    mysql -u root <<EOF
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${NEW_ROOT_PASSWORD}';
    DELETE FROM mysql.user WHERE User='';
    DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost');
    DROP DATABASE IF EXISTS test;
    DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
    CREATE DATABASE db_glpi;
    FLUSH PRIVILEGES;
EOF

    # Télécharger le dernier package GLPI depuis le dépôt officiel
    cd /var/www/html
    echo "Téléchargement du répertoire glpi à jour..."
    wget https://github.com/glpi-project/glpi/releases/download/${version}/glpi-${version}.tgz && echo "Téléchargement réussi !" || { echo -e "\E[31mErreur : échec du téléchargement.\E[0m"; exit 1; }
    echo "Décompression du répertoire GLPI..."
    tar xvzf glpi-${version}.tgz && echo "Décompression réussie !" || { echo -e "\E[31mErreur : échec de la décompression.\E[0m"; exit 1; }
    rm -r glpi-${version}.tgz

    # Ajout des droits à Apache
    chown -R www-data:www-data /var/www/html/glpi/ 
    chown -R www-data:www-data /var/www/html/glpi/plugins
    chown -R www-data:www-data /var/www/html/glpi/marketplace
    chmod -R 764 /var/www/html/glpi/plugins
    chmod -R 764 /var/www/html/glpi/marketplace

    # Création du répertoire /etc/glpi
    mkdir /etc/glpi
    chown www-data:www-data /etc/glpi/
    mv /var/www/html/glpi/config /etc/glpi

    # Création du répertoire  /var/lib/glpi
    mkdir  /var/lib/glpi
    chown www-data:www-data  /var/lib/glpi
    mv /var/www/html/glpi/files  /var/lib/glpi

    # Création du répertoire /var/log/glpi
    mkdir /var/log/glpi
    chown www-data:www-data /var/log/glpi

    #Création des fichiers de configuration
    touch /var/www/html/glpi/inc/downstream.php

    cat <<EOF >> /var/www/html/glpi/inc/downstream.php
    <?php
    define('GLPI_CONFIG_DIR', '/etc/glpi/');
    if (file_exists(GLPI_CONFIG_DIR . '/local_define.php')) {
        require_once GLPI_CONFIG_DIR . '/local_define.php';
    }
EOF
    touch /etc/glpi/local_define.php
    cat <<EOF >> /etc/glpi/local_define.php
    <?php
    define('GLPI_VAR_DIR', '/var/lib/glpi/files');
    define('GLPI_LOG_DIR', '/var/log/glpi');
EOF
    # Redémarrer le serveur Apache pour appliquer les changements
    a2enmod rewrite
    a2enmod proxy_fcgi setenvif
    a2enconf php8.2-fpm
    sed -i 's/^session.cookie_httponly\s*=.*/session.cookie_httponly = on/' /etc/php/8.2/fpm/php.ini
    echo "Démarrage de GLPI..."
    systemctl restart apache2 php8.2-fpm.service && echo "GLPI est maintenant en ligne identifiant et mot de passe par défaut glpi/glpi ! http://$ip_server" || { echo -e "\E[31mErreur : échec du redémarrage de GLPI.\E[0m"; exit 1; }

    # Sécurité Suppression du script d'installation
    rm /var/www/html/glpi/install/install.php
    rm $chemin/script_installation_glpi.bash && echo "Suppression du script d'installation !" || { echo -e "\E[31mErreur : échec suppression du script d'installation.\E[0m"; exit 1; }

else
    echo "Installation annulée."
    exit 1  # Quitte le script si l'utilisateur répond "non"
fi
