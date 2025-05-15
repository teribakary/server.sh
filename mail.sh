# Fusion des trois scripts en un seul script tout-en-un
combined_script = """#!/bin/bash

echo "==============================="
echo "📦 Installation de Postfix"
echo "==============================="
sudo dnf install -y postfix mailx

echo "🔧 Configuration Postfix..."
sudo postconf -e "myhostname = mail.local"
sudo postconf -e "mydomain = local"
sudo postconf -e "myorigin = $mydomain"
sudo postconf -e "inet_interfaces = all"
sudo postconf -e "mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain"
sudo postconf -e "mynetworks = 127.0.0.0/8"
sudo postconf -e "home_mailbox = Maildir/"
sudo postconf -e "smtpd_banner = $myhostname ESMTP"
sudo postconf -e "local_transport = local"

echo "📂 Création des Maildirs pour utilisateurs locaux..."
for user in alice bob; do
  if ! id "$user" &>/dev/null; then
    sudo useradd -m -s /bin/bash $user
  fi
  sudo mkdir -p /home/$user/Maildir
  sudo chown -R $user:$user /home/$user/Maildir
done

sudo systemctl enable --now postfix

echo "==============================="
echo "📦 Installation de Dovecot"
echo "==============================="
sudo dnf install -y dovecot

echo "🔧 Configuration Dovecot..."
sudo tee /etc/dovecot/dovecot.conf > /dev/null <<EOF
listen = *
protocols = imap pop3
disable_plaintext_auth = no
mail_privileged_group = mail
EOF

sudo tee /etc/dovecot/conf.d/10-auth.conf > /dev/null <<EOF
disable_plaintext_auth = no
auth_mechanisms = plain login
!include auth-system.conf.ext
EOF

sudo tee /etc/dovecot/conf.d/10-mail.conf > /dev/null <<EOF
mail_location = maildir:~/Maildir
EOF

sudo tee /etc/dovecot/conf.d/10-master.conf > /dev/null <<EOF
service imap-login {
  inet_listener imap {
    port = 143
  }
}
service pop3-login {
  inet_listener pop3 {
    port = 110
  }
}
EOF

sudo systemctl enable --now dovecot

echo "==============================="
echo "📦 Installation de Bind (DNS)"
echo "==============================="
sudo dnf install -y bind bind-utils

echo "🔧 Configuration de zone DNS locale..."

# Création du fichier de zone
sudo mkdir -p /etc/named/zones
sudo tee /etc/named/zones/db.mail.local > /dev/null <<EOF
$TTL 86400
@   IN  SOA mail.local. root.mail.local. (
            2025051501 ; Serial
            3600       ; Refresh
            1800       ; Retry
            604800     ; Expire
            86400 )    ; Minimum TTL

@       IN  NS    mail.local.
@       IN  A     127.0.0.1
mail    IN  A     127.0.0.1
EOF

# named.conf
sudo tee /etc/named.conf > /dev/null <<EOF
options {
    listen-on port 53 { 127.0.0.1; };
    directory       "/var/named";
    allow-query     { localhost; };
    recursion yes;
};

zone "mail.local" IN {
    type master;
    file "/etc/named/zones/db.mail.local";
};
EOF

sudo chown -R named:named /etc/named/zones

sudo systemctl enable --now named

# Configuration DNS locale
sudo tee /etc/resolv.conf > /dev/null <<EOF
nameserver 127.0.0.1
search local
EOF

echo "✅ Installation et configuration complètes !"
echo "➡️ Test DNS : dig mail.local"
echo "➡️ Test mail : mail bob@local depuis alice"
"""

# Sauvegarde du script combiné
with open("/mnt/data/install_mail_stack.sh", "w") as f:
    f.write(combined_script)

"/mnt/data/install_mail_stack.sh"
