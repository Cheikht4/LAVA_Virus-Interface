#!/bin/bash
# ==============================================================================
# Script de deploiement automatise pour LAVA-DNA (Production)
# Automated deployment script for LAVA-DNA (Production)
# ==============================================================================
set -e

echo "=== Deploiement LAVA-DNA sur serveur de production ==="
echo "======================================================="

# Configuration par defaut / Default configuration
DOMAIN="${DOMAIN:-your-domain.com}"
EMAIL="${EMAIL:-admin@your-domain.com}"
LAVA_PATH="/opt/lava-dna"
LAVA_USER="lavauser"
LAVA_ENV_FILE="/etc/lava-dna/lava.env"

# Couleurs pour l'affichage / Output colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verifier les privileges root / Verify root privileges
if [[ $EUID -ne 0 ]]; then
   print_error "Ce script doit etre execute en tant que root (ou avec sudo)."
   exit 1
fi

print_status "1. Mise a jour des paquets systeme..."
apt update && apt upgrade -y

print_status "2. Installation des dependances systeme, Perl et binaires..."
apt install -y \
    nginx \
    python3 \
    python3-pip \
    python3-venv \
    perl \
    build-essential \
    cpanminus \
    bioperl \
    primer3 \
    libmodule-build-perl \
    libdata-stag-perl \
    libgetopt-long-descriptive-perl \
    liblist-moreutils-perl \
    libparallel-forkmanager-perl \
    libxml-libxml-perl \
    certbot \
    python3-certbot-nginx \
    git \
    curl \
    htop \
    ufw

print_status "3. Installation et verification des modules BioPerl essentiels..."
cpanm Bio::Perl Bio::SeqIO Bio::AlignIO Bio::SimpleAlign Bio::LocatableSeq Parallel::ForkManager

print_status "4. Verification des binaires scientifiques (primer3_core, oligotm)..."
if command -v primer3_core &>/dev/null; then
    print_status "primer3_core detecte : $(command -v primer3_core)"
else
    print_warning "primer3_core non trouve dans le PATH standard. Verification des alternatives..."
fi

print_status "5. Creation du compte systeme dedie ($LAVA_USER)..."
if ! id "$LAVA_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$LAVA_USER"
    print_status "Utilisateur $LAVA_USER cree."
else
    print_status "Utilisateur $LAVA_USER existe deja."
fi

print_status "6. Preparation de l'arborescence et des dossiers d'execution..."
mkdir -p "$LAVA_PATH"
mkdir -p "$LAVA_PATH/uploads"
mkdir -p "$LAVA_PATH/results"
mkdir -p /var/log/lava
mkdir -p /var/run/lava
mkdir -p /etc/lava-dna

chown -R "$LAVA_USER:$LAVA_USER" "$LAVA_PATH" /var/log/lava /var/run/lava
chmod 750 "$LAVA_PATH/uploads" "$LAVA_PATH/results"

# Si le script est lance depuis un clone local, copier les fichiers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ "$SCRIPT_DIR" != "$LAVA_PATH" ] && [ -f "$SCRIPT_DIR/lava_flask_app.py" ]; then
    print_status "Synchronisation des fichiers sources vers $LAVA_PATH..."
    cp -r "$SCRIPT_DIR/"* "$LAVA_PATH/"
    chown -R "$LAVA_USER:$LAVA_USER" "$LAVA_PATH"
fi

print_status "7. Configuration du fichier d'environnement et cle secrete (/etc/lava-dna/lava.env)..."
if [ ! -f "$LAVA_ENV_FILE" ]; then
    GENERATED_SECRET=$(python3 -c 'import secrets; print(secrets.token_hex(32))')
    echo "SECRET_KEY=$GENERATED_SECRET" > "$LAVA_ENV_FILE"
    print_status "Cle SECRET_KEY persistante generee."
else
    print_status "Fichier $LAVA_ENV_FILE existant conserve."
fi
chown "$LAVA_USER:$LAVA_USER" "$LAVA_ENV_FILE"
chmod 600 "$LAVA_ENV_FILE"

print_status "8. Creation du virtualenv Python et installation des dependances..."
sudo -u "$LAVA_USER" python3 -m venv "$LAVA_PATH/venv"
sudo -u "$LAVA_USER" "$LAVA_PATH/venv/bin/pip" install --upgrade pip
sudo -u "$LAVA_USER" "$LAVA_PATH/venv/bin/pip" install -r "$LAVA_PATH/requirements_flask.txt"

print_status "9. Verification rapide de la configuration Flask..."
sudo -u "$LAVA_USER" "$LAVA_PATH/venv/bin/python" -c "
import os
import flask
import gunicorn
print('Flask version:', flask.__version__)
print('Gunicorn version:', gunicorn.__version__)
"

print_status "10. Configuration du service systemd..."
cp "$LAVA_PATH/deployment/lava-dna.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable lava-dna

print_status "11. Configuration de Nginx..."
cp "$LAVA_PATH/deployment/nginx_lava.conf" /etc/nginx/sites-available/lava-dna
if [ "$DOMAIN" != "your-domain.com" ]; then
    sed -i "s/your-domain.com/$DOMAIN/g" /etc/nginx/sites-available/lava-dna
fi
ln -sf /etc/nginx/sites-available/lava-dna /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl enable nginx

print_status "12. Configuration des taches de nettoyage automatique (cron)..."
(crontab -u "$LAVA_USER" -l 2>/dev/null | grep -v "$LAVA_PATH"; echo "0 2 * * * find $LAVA_PATH/uploads -type f -mtime +2 -delete") | crontab -u "$LAVA_USER" -
(crontab -u "$LAVA_USER" -l 2>/dev/null | grep -v "$LAVA_PATH"; echo "0 3 * * * find $LAVA_PATH/results -type f -mtime +7 -delete") | crontab -u "$LAVA_USER" -

print_status "13. Configuration de la rotation des logs (logrotate)..."
cat > /etc/logrotate.d/lava-dna << 'EOF'
/var/log/lava/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 lavauser lavauser
    sharedscripts
    postrotate
        systemctl reload lava-dna > /dev/null 2>&1 || true
    endscript
}
EOF

print_status "14. Demarrage des services..."
systemctl restart lava-dna
systemctl restart nginx

sleep 3
if systemctl is-active --quiet lava-dna; then
    print_status "Service LAVA-DNA : [ACTIF]"
else
    print_error "Echec du demarrage du service LAVA-DNA"
    journalctl -u lava-dna -n 20 --no-pager
    exit 1
fi

if systemctl is-active --quiet nginx; then
    print_status "Service Nginx : [ACTIF]"
else
    print_error "Echec du demarrage du service Nginx"
    systemctl status nginx --no-pager
    exit 1
fi

echo ""
echo "======================================================="
echo " Deploiement termine avec succes !"
echo "======================================================="
echo ""
echo " Commandes utiles pour la supervision :"
echo " - Logs Flask/Gunicorn : journalctl -u lava-dna -f"
echo " - Logs Nginx          : tail -f /var/log/nginx/lava_error.log"
echo " - Redemarrer LAVA     : systemctl restart lava-dna"
echo " - Statut du service   : systemctl status lava-dna"
echo ""
echo " Pour activer SSL via Let's Encrypt une fois le DNS configure :"
echo " certbot --nginx -d $DOMAIN --agree-tos --email $EMAIL"
echo ""
