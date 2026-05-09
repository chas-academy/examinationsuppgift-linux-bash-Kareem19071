#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Måste vara root"
  exit 1
fi

for USERNAME in "$@"
do
  useradd -m "$USERNAME"

  mkdir -p /home/$USERNAME/Documents
  mkdir -p /home/$USERNAME/Downloads
  mkdir -p /home/$USERNAME/Work

  echo "Välkommen $USERNAME" > /home/$USERNAME/welcome.txt
  cut -d: -f1 /etc/passwd >> /home/$USERNAME/welcome.txt

  chown -R $USERNAME:$USERNAME /home/$USERNAME
done#!/bin/bash

echo "Hej"
