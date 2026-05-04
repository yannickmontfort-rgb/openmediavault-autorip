# openmediavault-autorip

## Plugin OMV 7 - AutoRip DVD vers dossier partagé

Ce plugin pour OpenMediaVault 7 permet le rip automatique de DVD en MKV dès l'insertion d'un disque dans le lecteur. Le fichier MKV est automatiquement transféré dans un dossier partagé configuré depuis l'interface OMV.

## Fonctionnalités

- Détection automatique de l'insertion d'un DVD via udev
- Décryptage CSS automatique via libdvdcss2 (clés récupérées sur keys.videolan.org)
- Rip en MKV via MakeMKV
- Transfert automatique vers un dossier partagé OMV
- Configuration via l'interface Web OMV 7
- Éjection automatique après rip (optionnel)
- Logs en temps réel

## Dépendances

- OpenMediaVault 7
- MakeMKV (makemkvcon)
- libdvdcss2
- Python 3
- udev

## Installation

```bash
git clone https://github.com/yannickmontfort-rgb/openmediavault-autorip
cd openmediavault-autorip
make build
make install
```

## Configuration

Une fois installé, configurez le plugin depuis OMV :
**Services → AutoRip DVD**

- Sélectionnez le dossier partagé destination
- Choisissez le périphérique DVD (/dev/sr0)
- Activez l'autorip

## Verification post-installation

Sur ton serveur OMV, lance un controle rapide de sante du plugin:

```bash
chmod +x tools/check_post_install.sh
sudo ./tools/check_post_install.sh
```

Le script verifie notamment:

- Installation du paquet
- Presence des fichiers OMV (RPC, module, routes, composants)
- Syntaxe PHP/Python
- Validite de /etc/openmediavault/autorip.conf
- Etat des services omv-engined, nginx, php-fpm et autorip.service

## Workflow en une commande

Pour builder, installer, redemarrer les services OMV et lancer la verification post-install en une fois:

```bash
sudo make deploy-check
```

## Debug erreur 500 OMV

Si l'interface OMV renvoie encore une erreur 500, collecte un bundle de diagnostic:

```bash
sudo make collect-500-debug
```

Le script genere un dossier /tmp/autorip-debug-YYYYMMDD-HHMMSS et une archive .tar.gz avec:

- etat des services omv-engined/nginx/php-fpm
- logs journalctl et nginx error.log
- lint PHP des fichiers du plugin
- contenu des fichiers YAML OMV et de la config autorip

## Licence

MIT
