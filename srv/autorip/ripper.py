#!/usr/bin/env python3
"""
Ripper - Lance MakeMKV pour ripper le DVD en MKV.
"""

import subprocess
import logging


def rip_dvd(device: str, output_dir: str, min_length: int = 1200):
    """
    Rip le DVD en MKV via makemkvcon.
    :param device: Périphérique DVD (ex: /dev/sr0)
    :param output_dir: Dossier de sortie temporaire
    :param min_length: Durée minimale en secondes (défaut 20 min)
    """
    logging.info(f"Lancement de MakeMKV sur {device} → {output_dir}")

    cmd = [
        "makemkvcon",
        "--robot",
        "--noscan",
        f"--minlength={min_length}",
        "mkv",
        f"dev:{device}",
        "all",
        output_dir
    ]

    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        logging.info(f"MakeMKV terminé : {result.stdout[-200:]}")
    except subprocess.CalledProcessError as e:
        logging.error(f"Erreur MakeMKV : {e.stderr}")
        raise
