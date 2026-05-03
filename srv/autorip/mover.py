#!/usr/bin/env python3
"""
Mover - Transfère les fichiers MKV vers le dossier partagé OMV.
"""

import shutil
import logging
from pathlib import Path


def move_to_share(src_dir: str, share_path: str):
    """
    Déplace tous les fichiers MKV du dossier temporaire vers le dossier partagé.
    :param src_dir: Dossier source temporaire
    :param share_path: Chemin du dossier partagé OMV destination
    """
    src = Path(src_dir)
    dest = Path(share_path)

    if not dest.exists():
        logging.error(f"Dossier partagé introuvable : {share_path}")
        raise FileNotFoundError(f"Dossier partagé introuvable : {share_path}")

    mkv_files = list(src.glob("*.mkv"))

    if not mkv_files:
        logging.warning("Aucun fichier MKV trouvé dans le dossier temporaire.")
        return

    for mkv in mkv_files:
        destination = dest / mkv.name
        logging.info(f"Déplacement : {mkv.name} → {share_path}")
        shutil.move(str(mkv), str(destination))
        logging.info(f"✅ {mkv.name} transféré avec succès.")
