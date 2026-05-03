#!/usr/bin/env python3
"""
Key Fetcher - Vérifie la présence de libdvdcss2 pour le décryptage CSS.
Les clés sont récupérées automatiquement depuis keys.videolan.org par libdvdcss2.
"""

import subprocess
import logging


def check_libdvdcss():
    """
    Vérifie que libdvdcss2 est installée sur le système.
    libdvdcss2 récupère automatiquement les clés CSS depuis keys.videolan.org.
    """
    try:
        result = subprocess.run(
            ["dpkg", "-l", "libdvdcss2"],
            capture_output=True, text=True
        )
        if "ii" in result.stdout:
            logging.info("libdvdcss2 est installée. Décryptage CSS disponible.")
        else:
            logging.warning("libdvdcss2 non trouvée ! Tentative d'installation...")
            subprocess.run(["apt-get", "install", "-y", "libdvdcss2"], check=True)
            logging.info("libdvdcss2 installée avec succès.")
    except Exception as e:
        logging.error(f"Erreur lors de la vérification de libdvdcss2 : {e}")
        raise
