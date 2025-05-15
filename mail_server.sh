#!/bin/bash

echo "🔍 Vérification de la configuration mail locale..."

# Vérification de Postfix
if ! systemctl is-active --quiet postfix; then
    echo "🚀 Démarrage de Postfix..."
    sudo systemctl enable --now postfix
else
    echo "✅ Postfix est déjà actif."
fi

# Vérifier l'existence du socket pickup
if [ ! -e /var/spool/postfix/public/pickup ]; then
    echo "⚠️ Socket pickup manquant. Redémarrage de Postfix..."
    sudo postfix check
    sudo postfix start
else
    echo "✅ Socket pickup OK."
fi

# Corriger les permissions sur /var/spool/mail
echo "🔧 Vérification des permissions sur /var/spool/mail..."
sudo chown root:mail /var/spool/mail
sudo chmod 770 /var/spool/mail

# Corriger les permissions pour chaque utilisateur
for user in alice bob; do
    if id "$user" &>/dev/null; then
        sudo touch /var/spool/mail/$user
        sudo chown $user:mail /var/spool/mail/$user
        sudo chmod 660 /var/spool/mail/$user
        echo "✅ Mailbox pour $user configurée."
    else
        echo "⚠️ Utilisateur $user introuvable."
    fi
done

# Vérifier que le paquet mailx est installé
if ! command -v mail &> /dev/null; then
    echo "📦 Installation de mailx (outil mail)..."
    sudo dnf install -y mailx
else
    echo "✅ mailx est déjà installé."
fi

echo "✅ Configuration terminée. Testez l'envoi de mail avec :"
echo "   mail alice@local"
