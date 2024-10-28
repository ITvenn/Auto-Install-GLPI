# Script d'Installation Automatique de GLPI

## Description

Ce script Bash permet l'installation automatique de GLPI (Gestionnaire Libre de Parc Informatique) sur un serveur Debian. Vous pouvez spécifier la version de GLPI que vous souhaitez installer, et il configure également Apache, PHP, MariaDB, et les paramètres nécessaires pour le bon fonctionnement de GLPI.

## Fonctionnalités

- Installation de la version souhaitée de GLPI à partir du dépôt GitHub officiel.
- Configuration automatique du serveur web Apache.
- Installation de PHP et des dépendances nécessaires pour GLPI.
- Configuration d'une base de données MariaDB avec un nouveau mot de passe root.
- Option pour installer `php-ldap` pour activer la synchronisation LDAP.
- Configuration de répertoires spécifiques pour les logs et les fichiers de configuration de GLPI.
- Sécurisation de l'installation avec la suppression du script d'installation une fois l'installation terminée.

## Prérequis

Avant d'exécuter ce script, assurez-vous d'avoir :
- Un serveur avec Debian 12.
- Effectuer une snapshot de votre Debian
- Les droits administrateurs (`sudo`).
- Une connexion Internet pour télécharger les paquets et GLPI.

## Utilisation

1. Clonez le dépôt ou téléchargez le script sur votre serveur :
   ```bash
   git clone <lien_du_depot>
   cd <dossier_du_depot>

2. Donnez les droits d'exécution au script :
   ```bash
   chmod +x script_installation_glpi.bash
   ```

3. Exécutez le script en tant qu'administrateur :
   ```bash
   sudo ./script_installation_glpi.bash
   ```

4. Le script vous demandera de saisir la version de GLPI souhaitée dans le format `X.X.X`. Exemple : `10.0.16`.

5. Vous devrez confirmer l'installation, entrer l'adresse IP de votre serveur, et configurer un mot de passe root pour la base de données MariaDB.

6. Si vous souhaitez utiliser la synchronisation LDAP, vous aurez l'option d'installer `php-ldap`.

7. À la fin de l'installation, GLPI sera accessible à l'adresse `http://<adresse_ip_du_serveur>`. Les identifiants par défaut sont `glpi/glpi`.

## Exemple d'utilisation

Voici un exemple de session d'installation :

```
$ sudo ./script_installation_glpi.bash
Veuillez entrer le numero de version GLPI souhaité dans le format suivant X.X.X : 10.0.16
Voulez-vous vraiment installer la version 10.0.16 de GLPI ? (o/n) : o
Installation de GLPI version 10.0.16...
Installation d'Apache
Veuillez entrer l'adresse IP de votre serveur dans le format suivant : X.X.X.X : 192.168.1.100
Installation de PHP...
...
GLPI est maintenant en ligne : http://192.168.1.100
Identifiant par défaut : glpi
Mot de passe par défaut : glpi
```

## Sécurité

- **Suppression automatique du script d'installation** : Une fois l'installation terminée avec succès, le script d'installation GLPI et le script Bash seront supprimés pour éviter tout problème de sécurité.
- **GLPI configuré pour utiliser des chemins sécurisés** : Les répertoires de configuration et de fichiers sont déplacés hors du répertoire racine du serveur web.

## Avertissement

Ce script a été testé uniquement sur des serveurs Debian. Assurez-vous de tester dans un environnement contrôlé avant de l'exécuter en production.

## Auteur

- Vincent HAMEL

## Licence

Ce script est fourni "tel quel", sans aucune garantie explicite ou implicite. Vous êtes libre de l'utiliser et de le modifier selon vos besoins.
