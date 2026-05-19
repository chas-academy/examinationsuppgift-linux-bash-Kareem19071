#!/bin/bash

################################################################################
# Script: create_users.sh
# Beskrivning: Automatiserat script för att skapa användare med katalogstruktur
# Författare: [Ditt namn]
# Användning: ./create_users.sh [användarnamn1] [användarnamn2] ...
################################################################################

# Kontrollera att scriptet körs som root (UID 0)
if [ "$EUID" -ne 0 ]; then
    echo "Fel: Detta script måste köras som root (sudo)."
    exit 1
fi

# Kontrollera att minst ett användarnamn har angetts
if [ $# -eq 0 ]; then
    echo "Användning: $0 [användarnamn1] [användarnamn2] ..."
    exit 1
fi

# Funktion för att hämta alla befintliga användare (UID >= 1000)
get_existing_users() {
    awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd
}

# Funktion som filtrerar bort oönskade eller temporära konton från välkomstlistan
ignore_user() {
    local user="$1"
    case "$user" in
        codespace|\$1|\$*) return 0 ;; # hoppa över devcontainer/systemkonto och shell-variabler i /etc/passwd
        *) return 1 ;;
    esac
}

# Funktion för att skapa en användare
create_user() {
    local username=$1
    
    # Kontrollera om användaren redan finns
    if id "$username" &>/dev/null; then
        echo "Användaren $username finns redan. Hoppar över..."
        return
    fi
    
    echo "Skapar användare: $username"
    
    # Skapa användaren med hemkatalog
    useradd -m -s /bin/bash "$username"
    
    # Kontrollera att användaren skapades framgångsrikt
    if [ $? -ne 0 ]; then
        echo "Fel: Kunde inte skapa användaren $username"
        return
    fi
    
    # Hämta användarens hemkatalog
    local user_home="/home/$username"
    
    # Skapa undermappar
    mkdir -p "$user_home/Documents"
    mkdir -p "$user_home/Downloads"
    mkdir -p "$user_home/Work"
    
    # Sätt rättigheter så endast ägaren kan läsa och skriva (700)
    chmod 700 "$user_home/Documents"
    chmod 700 "$user_home/Downloads"
    chmod 700 "$user_home/Work"
    
    # Sätt rätt ägare på mapparna
    chown -R "$username:$username" "$user_home/Documents"
    chown -R "$username:$username" "$user_home/Downloads"
    chown -R "$username:$username" "$user_home/Work"
    
    echo "Användaren $username har skapats framgångsrikt!"
    echo "---"
}

# Funktion för att skapa välkomstfilen efter att alla användare skapats
create_welcome() {
    local username=$1
    local user_home="/home/$username"
    local welcome_file="$user_home/welcome.txt"

    if [ ! -d "$user_home" ]; then
        echo "Fel: Hemkatalogen för $username finns inte."
        return
    fi

    echo "Välkommen $username" > "$welcome_file"
    echo "" >> "$welcome_file"
    echo "Andra användare i systemet:" >> "$welcome_file"

    get_existing_users | while read -r other_user; do
        if [ "$other_user" != "$username" ] && ! ignore_user "$other_user"; then
            echo "- $other_user" >> "$welcome_file"
        fi
    done

    chown "$username:$username" "$welcome_file"
    chmod 644 "$welcome_file"
}

# Huvudloop - skapa alla användare som angetts som argument
for username in "$@"; do
    create_user "$username"
done

# Skapa välkomstfiler när alla användare har skapats
for username in "$@"; do
    create_welcome "$username"
done

echo "Alla användare har bearbetats."