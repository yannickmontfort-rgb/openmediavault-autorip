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

## Licence

MIT
