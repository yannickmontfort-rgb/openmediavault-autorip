#!/usr/bin/env python3
"""
Encoder - Compression H.264/H.265 via HandBrakeCLI après le rip MKV.
"""

import subprocess
import logging
import os
from pathlib import Path


def encode_mkv(output_dir: str, codec: str = "x264", quality: int = 22,
               preset: str = "medium", enabled: bool = True):
    """
    Compresse les fichiers MKV via HandBrakeCLI.
    :param output_dir: Dossier contenant les MKV à encoder
    :param codec: Codec vidéo : x264 (H.264) ou x265 (H.265)
    :param quality: Qualité RF (0=meilleure, 51=pire) - défaut 22
    :param preset: Vitesse d'encodage : ultrafast, fast, medium, slow, veryslow
    :param enabled: Si False, l'encodage est ignoré
    """
    if not enabled:
        logging.info("Encodage HandBrake désactivé, étape ignorée.")
        return

    mkv_files = list(Path(output_dir).glob("*.mkv"))
    if not mkv_files:
        logging.warning("Aucun MKV trouvé pour l'encodage.")
        return

    for mkv in mkv_files:
        encoded = mkv.parent / f"encoded_{mkv.name}"
        logging.info(f"Encodage {codec.upper()} [{preset}] RF={quality} : {mkv.name}")

        cmd = [
            "HandBrakeCLI",
            "-i", str(mkv),
            "-o", str(encoded),
            "--encoder", codec,
            "--quality", str(quality),
            "--encoder-preset", preset,
            "--format", "av_mkv",
            "--audio-copy-mask", "aac,ac3,eac3,truehd,dts,dtshd,mp3,flac",
            "--audio-fallback", "ffaac",
            "--subtitle-burned", "none",
            "--all-subtitles"
        ]

        try:
            subprocess.run(cmd, check=True, capture_output=True, text=True)
            os.replace(str(encoded), str(mkv))
            logging.info(f"✅ Encodage terminé : {mkv.name}")
        except subprocess.CalledProcessError as e:
            logging.error(f"Erreur HandBrake sur {mkv.name} : {e.stderr}")
            if encoded.exists():
                encoded.unlink()
            raise
