# ytdl — Téléchargeur YouTube

## Objectif
Script en Bash qui permet de télécharger des vidéos et playlists YouTube
depuis le terminal, avec un menu interactif.

## Fonctionnalités
- Télécharger une vidéo en meilleure qualité (MP4)
- Choisir la qualité (360p, 720p, 1080p, 4K)
- Extraire l'audio en MP3
- Télécharger une playlist complète
- Télécharger les sous-titres
- Voir les formats disponibles pour une URL

## Contraintes techniques
- Tout dans un seul fichier Bash (.sh)
- Pas de dépendances sauf yt-dlp et ffmpeg
- Installation automatique de yt-dlp si absent
- Compatible Ubuntu 24.04
- Dossier de destination par défaut : ~/Téléchargements/Youtube

## Ce que le script ne fait PAS
- Pas d'interface graphique
- Pas de téléchargement en arrière-plan
- Pas de gestion de comptes ou cookies