#!/usr/bin/env bash
set -e

echo "==> Redémarrage du démon Docker utilisateur"
systemctl --user restart docker || true

echo "==> Suppression de l'ancien conteneur"
docker rm -f jenkins_server 2>/dev/null || true

echo "==> Désactivation de la sécurité dans le volume jenkins-data"
docker run --rm -u root \
  -v jenkins-data:/var/jenkins_home \
  --entrypoint sed \
  jenkins/jenkins:lts \
  -i 's|<useSecurity>true</useSecurity>|<useSecurity>false</useSecurity>|' \
  /var/jenkins_home/config.xml

echo "==> Démarrage de Jenkins"
docker run -d -u root -p 8080:8080 \
  -v jenkins-data:/var/jenkins_home \
  -v "$(which docker)":/usr/bin/docker \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$HOME":/home \
  --name jenkins_server \
  jenkins/jenkins:lts

echo "Jenkins démarre sur http://localhost:8080 (sans identifiant)."
