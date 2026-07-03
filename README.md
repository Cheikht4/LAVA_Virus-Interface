# LAVA-DNA Web Interface & Production Deployment Package

## Description (Français)

Ce dépôt constitue le package officiel autonome de l'interface graphique web (Flask / Gunicorn / Nginx) et du moteur scientifique LAVA pour le design avancé d'amorces LAMP (Loop-Mediated Isothermal Amplification). Il est optimisé pour un déploiement clé en main sur serveur de production ou une exécution locale simple par les chercheurs.

### Fonctionnalités principales
- **Interface bilingue complète (FR / EN)** : Bascule instantanée de la langue pour la configuration, la surveillance en temps réel (barre de progression LAVA-Progress) et les diagnostics d'échec.
- **Support des virus variables et références uniques** : Calcul combinatoire proportionnel à la taille de la région cible avec tolérance aux codes IUPAC et validation d'alignement FASTA.
- **Sécurité et Robustesse** : Cookies de session sécurisés (`HttpOnly`, `SameSite=Lax`), contrôle d'intégrité des fichiers téléchargés et gestion d'arrière-plan résiliente.
- **Package de Déploiement Production** : Fichiers de configuration Nginx (`deployment/nginx_lava.conf`), service systemd (`deployment/lava-dna.service`) et Gunicorn (`deployment/gunicorn_config.py`).

---

## Description (English)

This repository provides the standalone web interface package (Flask / Gunicorn / Nginx) and LAVA scientific engine for advanced LAMP primer design. It is streamlined for turnkey production server deployment or simple local execution.

### Key Features
- **Full Bilingual Interface (FR / EN)** : Instant language switching across parameter configuration, live monitoring (LAVA-Progress bar), and technical error diagnosis.
- **Support for Highly Variable Viruses & Single References** : Proportional combinatorial search with unrestricted IUPAC degeneracy support and strict FASTA alignment validation.
- **Security & Robustness** : Hardened session cookies (`HttpOnly`, `SameSite=Lax`), upload validation, and resilient background task management.
- **Production Deployment Suite** : Includes Nginx configuration (`deployment/nginx_lava.conf`), systemd service files (`deployment/lava-dna.service`), and Gunicorn configuration (`deployment/gunicorn_config.py`).

---

## Guide d'Installation Rapide / Quick Start Guide

### 1. Installation locale (Développement / Utilisation directe)

```bash
# 1. Créer et activer l'environnement virtuel Python
python3 -m venv lava_env
source lava_env/bin/activate

# 2. Installer les dépendances Python
pip install -r requirements_flask.txt

# 3. Installer les dépendances Perl / Conda (si non présentes sur le système)
# Assurez-vous d'avoir Perl, Primer3 et BioPerl installés via environment.yml

# 4. Lancer l'application Flask
python3 lava_flask_app.py
```
Ouvrez ensuite votre navigateur sur : `http://127.0.0.1:5000`

---

### 2. Déploiement en Production (Linux / Nginx / Gunicorn)

Consultez le dossier `deployment/` qui contient les scripts automatisés :
```bash
# Exécution du script de déploiement (nécessite les privilèges root/sudo)
cd deployment/
chmod +x deploy.sh
sudo ./deploy.sh
```

---
## Architecture du Répertoire

- `lava_flask_app.py` : Contrôleur principal Flask et gestionnaire de tâches asynchrones.
- `launch_lava_smart_kill.py` : Gestionnaire d'arrêt propre des processus en arrière-plan.
- `templates/` : Pages HTML bilingues (`index.html`, `monitor.html`, `executions.html`).
- `static/` : Styles CSS et assets graphiques.
- `deployment/` : Scripts et fichiers de configuration pour la production (Nginx/systemd).
- `lava_loop_primer.pl` / `lava_stem_primer.pl` : Moteurs scientifiques Perl.
- `lib/` : Modules algorithmiques et thermodynamiques Perl LAVA.
