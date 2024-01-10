#!/bin/bash

# Dateipfad für die Speicherung der alten und vorherigen MAC-Adresse sowie des Schnittstellennamens
DB_FILE="database.yml"

# Funktion, um eine zufällige MAC-Adresse zu generieren
generate_random_mac() {
  echo "$(printf '%02X' $((RANDOM%256))):$(printf '%02X' $((RANDOM%256))):$(printf '%02X' $((RANDOM%256))):$(printf '%02X' $((RANDOM%256))):$(printf '%02X' $((RANDOM%256))):$(printf '%02X' $((RANDOM%256)))"
}

# Hinweis zum Abrufen der Informationen über die Netzwerkschnittstelle
echo "Um fortzufahren, benötigst du Informationen über deine Netzwerkschnittstelle (z.B., wlp2s0)."
echo "Du kannst diese Informationen mit dem Befehl 'ip link show' oder 'ifconfig' abrufen."

# Abfrage des Schnittstellennamens
echo "Gib den Namen der Schnittstelle ein:"
read interface

# Überprüfen, ob die Schnittelle existiert
if ! ip link show "$interface" > /dev/null 2>&1; then
  echo "Schnittelle $interface nicht gefunden. Das Skript wird beendet."
  exit 1
fi

# Überprüfen, ob eine database.yml existiert
if [ ! -f "$DB_FILE" ]; then
  echo "Erstelle $DB_FILE..."
  echo -e "original_mac: \nprevious_mac: \ninterface: $interface" > "$DB_FILE"
fi

# Laden der ursprünglichen MAC-Adresse aus der database.yml
original_mac=$(awk '/original_mac/ {print $2}' "$DB_FILE")
if [ -z "$original_mac" ]; then
  original_mac=$(ip addr show dev "$interface" | awk '/ether/ {print $2}')
fi

# Laden der vorherigen MAC-Adresse aus der database.yml
previous_mac=$(awk '/previous_mac/ {print $2}' "$DB_FILE")

# Speichern der ursprünglichen und vorherigen MAC-Adresse sowie des Schnittstellennamens in der database.yml
echo -e "original_mac: $original_mac\nprevious_mac: $previous_mac\ninterface: $interface" > "$DB_FILE"

# Abfrage, ob die ursprüngliche MAC-Adresse wiederhergestellt werden soll
echo "Möchtest du die ursprüngliche MAC-Adresse wiederherstellen? (ja/nein)"
read restore_original_mac

if [ "$restore_original_mac" == "ja" ]; then
  new_mac="$original_mac"
else
  # Abfrage, ob eine zufällige MAC-Adresse generiert oder eine spezifische eingegeben werden soll
  echo "Möchtest du eine zufällige MAC-Adresse generieren? (ja/nein)"
  read random_mac_choice

  if [ "$random_mac_choice" == "ja" ]; then
    new_mac=$(generate_random_mac)
  else
    echo "Gib die gewünschte MAC-Adresse ein (Format: XX:XX:XX:XX:XX:XX):"
    read new_mac
  fi
fi

# Überprüfen, ob die generierte/spezifizierte MAC-Adresse gültig ist
if ! sudo ip link set dev "$interface" down; then
  echo "Fehler: Konnte die Schnittstelle nicht herunterfahren."
  exit 1
fi

if ! sudo ip link set dev "$interface" address "$new_mac"; then
  echo "Fehler: Die generierte/spezifizierte MAC-Adresse ist ungültig oder wird nicht unterstützt."
  exit 1
fi

# Hochfahren der Schnittstelle
sudo ip link set dev "$interface" up

# Aktualisieren der vorherigen MAC-Adresse in der database.yml
echo -e "original_mac: $original_mac\nprevious_mac: $new_mac\ninterface: $interface" > "$DB_FILE"

echo "Neue MAC-Adresse wurde für $interface gesetzt."

exit 0

