#!/usr/bin/env python3
"""
Ripper - Lance MakeMKV pour ripper le DVD en MKV.
Support sélection langues audio et sous-titres via mkvmerge.
"""

import subprocess
import logging
import os
from pathlib import Path


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


def filter_languages(output_dir: str, audio_langs: list, subtitle_langs: list,
                     keep_all_audio: bool = False, keep_all_subtitles: bool = False):
    """
    Filtre les pistes audio et sous-titres des MKV via mkvmerge.
    :param output_dir: Dossier contenant les fichiers MKV
    :param audio_langs: Liste des codes langue audio ISO 639-2 (ex: ['fra', 'eng'])
    :param subtitle_langs: Liste des codes langue sous-titres ISO 639-2
    :param keep_all_audio: Si True, conserve toutes les pistes audio
    :param keep_all_subtitles: Si True, conserve tous les sous-titres
    """
    if keep_all_audio and keep_all_subtitles:
        logging.info("Conservation de toutes les pistes audio et sous-titres.")
        return

    mkv_files = list(Path(output_dir).glob("*.mkv"))
    if not mkv_files:
        logging.warning("Aucun MKV trouvé pour le filtrage des langues.")
        return

    for mkv in mkv_files:
        filtered = mkv.parent / f"filtered_{mkv.name}"
        cmd = ["mkvmerge", "-o", str(filtered)]

        # Pistes audio
        if not keep_all_audio and audio_langs:
            cmd += ["--audio-tracks", ",".join(audio_langs)]
            logging.info(f"Langues audio conservées : {', '.join(audio_langs)}")

        # Sous-titres
        if not keep_all_subtitles and subtitle_langs:
            cmd += ["--subtitle-tracks", ",".join(subtitle_langs)]
            logging.info(f"Langues sous-titres conservées : {', '.join(subtitle_langs)}")

        cmd.append(str(mkv))

        try:
            subprocess.run(cmd, check=True, capture_output=True, text=True)
            os.replace(str(filtered), str(mkv))
            logging.info(f"✅ Filtrage langues appliqué : {mkv.name}")
        except subprocess.CalledProcessError as e:
            logging.error(f"Erreur mkvmerge sur {mkv.name} : {e.stderr}")
            if filtered.exists():
                filtered.unlink()
            raise
