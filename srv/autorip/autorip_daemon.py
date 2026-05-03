#!/usr/bin/env python3
"""
Autorip Daemon - Plugin OMV 7
Détecte l'insertion d'un DVD et lance le rip automatique.
"""

import argparse
import logging
import os
import json

from ripper import rip_dvd, filter_languages
from mover import move_to_share
from key_fetcher import check_libdvdcss

CONFIG_FILE = "/etc/openmediavault/autorip.conf"
LOG_FILE = "/var/log/autorip.log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [AutoRip] %(levelname)s: %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ]
)

def load_config():
    with open(CONFIG_FILE) as f:
        return json.load(f)

def main(device: str):
    config = load_config()

    if not config.get("enable", False):
        logging.info("AutoRip désactivé dans la configuration.")
        return

    tmp_dir            = config.get("tmp_dir", "/tmp/autorip")
    share              = config.get("share_path", "")
    eject              = config.get("eject_after", True)
    audio_langs        = config.get("audio_languages", ["fra", "eng"])
    subtitle_langs     = config.get("subtitle_languages", ["fra", "eng"])
    keep_all_audio     = config.get("keep_all_audio", False)
    keep_all_subtitles = config.get("keep_all_subtitles", False)

    if not share:
        logging.error("Aucun dossier partagé configuré !")
        return

    os.makedirs(tmp_dir, exist_ok=True)

    logging.info(f"DVD détecté sur {device}, vérification libdvdcss2...")
    check_libdvdcss()

    logging.info("Début du rip...")
    rip_dvd(device, tmp_dir, config.get("min_length", 1200))

    logging.info("Filtrage des langues audio et sous-titres...")
    filter_languages(tmp_dir, audio_langs, subtitle_langs, keep_all_audio, keep_all_subtitles)

    logging.info("Transfert vers le dossier partagé...")
    move_to_share(tmp_dir, share)

    if eject:
        os.system(f"eject {device}")
        logging.info(f"Disque éjecté : {device}")

    logging.info("✅ Rip terminé avec succès !")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="AutoRip DVD Daemon")
    parser.add_argument("--device", required=True, help="Périphérique DVD (ex: /dev/sr0)")
    args = parser.parse_args()
    main(args.device)
