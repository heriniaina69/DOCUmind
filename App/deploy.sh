#!/bin/bash
set -e

PORT="${1:-5000}"
IMAGE_NAME="flask-bonjour"
CONTAINER_NAME="app-bonjour"
APP_DIR="./flask-bonjour-app"

echo "=== Création du projet dans $APP_DIR sur le port $PORT ==="
mkdir -p "$APP_DIR/templates"

# 1. requirements.txt
cat << 'EOF' > "$APP_DIR/requirements.txt"
flask==3.1.0
gunicorn==23.0.0
EOF

# 2. Code de l'application Flask (app.py)
cat << 'EOF' > "$APP_DIR/app.py"
from flask import Flask, render_template

app = Flask(__name__)

@app.route("/")
def index():
    return render_template("index.html")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
EOF

# 3. Template HTML (templates/index.html)
cat << 'EOF' > "$APP_DIR/templates/index.html"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bonjour Monsieur</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            margin: 0;
            padding: 20px;
            background-color: #f4f4f9;
            color: #333;
        }
        .carte {
            background: #ffffff;
            padding: 30px;
            border-radius: 12px;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
            text-align: center;
            max-width: 450px;
            width: 100%;
        }
        .actions {
            display: flex;
            gap: 12px;
            justify-content: center;
            flex-wrap: wrap;
        }
        button {
            padding: 12px 22px;
            font-size: 16px;
            cursor: pointer;
            border: none;
            border-radius: 8px;
            color: white;
        }
        #btn-cliquer {
            background-color: #007bff;
        }
        #btn-cliquer:hover {
            background-color: #0056b3;
        }
        #btn-retour {
            background-color: #6c757d;
        }
        #btn-retour:hover {
            background-color: #545b62;
        }
        #message {
            margin-top: 22px;
            font-size: 22px;
            font-weight: bold;
            color: #198754;
            min-height: 30px;
        }
        .historique {
            margin-top: 28px;
            padding-top: 18px;
            border-top: 1px solid #e5e7eb;
            text-align: left;
        }
        .historique h2 {
            font-size: 16px;
            margin: 0 0 10px 0;
            color: #4b5563;
        }
        #liste-historique {
            list-style: none;
            padding: 0;
            margin: 0;
        }
        #liste-historique li {
            background: #f8f9fa;
            border-left: 4px solid #007bff;
            padding: 8px 12px;
            margin-bottom: 8px;
            border-radius: 4px;
            font-size: 15px;
        }
        .vide {
            color: #888;
            font-style: italic;
            font-size: 14px;
        }
    </style>
</head>
<body>

    <div class="carte">
        <div class="actions">
            <button id="btn-cliquer" onclick="demanderNom()">Cliquer ici</button>
            <button id="btn-retour" onclick="faireRetour()">Retour</button>
        </div>

        <div id="message"></div>

        <div class="historique">
            <h2>Historique des personnes saluées</h2>
            <ul id="liste-historique">
                <li class="vide">Aucune personne saluée pour le moment.</li>
            </ul>
        </div>
    </div>

    <script>
        const historique = [];

        function demanderNom() {
            const nomSaisi = prompt("Veuillez entrer votre nom :");

            if (nomSaisi === null) {
                return;
            }

            const nomNettoye = nomSaisi.trim();
            if (nomNettoye === "") {
                alert("Veuillez entrer un nom valide.");
                return;
            }

            document.getElementById("message").innerText = `Bonjour ${nomNettoye} !`;

            const heure = new Date().toLocaleTimeString("fr-FR", {
                hour: "2-digit",
                minute: "2-digit",
                second: "2-digit"
            });

            historique.unshift({ nom: nomNettoye, heure: heure });
            afficherHistorique();
        }

        function faireRetour() {
            document.getElementById("message").innerText = "";
        }

        function afficherHistorique() {
            const ul = document.getElementById("liste-historique");
            ul.innerHTML = "";

            if (historique.length === 0) {
                ul.innerHTML = '<li class="vide">Aucune personne saluée pour le moment.</li>';
                return;
            }

            historique.forEach((item) => {
                const li = document.createElement("li");
                li.textContent = `${item.nom} — salué(e) à ${item.heure}`;
                ul.appendChild(li);
            });
        }
    </script>

</body>
</html>
EOF

# 4. Dockerfile (avec port dynamique via ARG / ENV)
cat << 'EOF' > "$APP_DIR/Dockerfile"
FROM python:3.12-slim

ARG PORT=5000
ENV PORT=${PORT}

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .
COPY templates/ ./templates/

EXPOSE ${PORT}

CMD ["sh", "-c", "gunicorn --bind 0.0.0.0:${PORT} app:app"]
EOF

echo "=== Construction de l'image Docker ==="
docker build --build-arg PORT="$PORT" -t "$IMAGE_NAME" "$APP_DIR"

if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
    echo "=== Arrêt et suppression de l'ancien conteneur $CONTAINER_NAME ==="
    docker rm -f "$CONTAINER_NAME"
fi

echo "=== Lancement du conteneur sur le port $PORT ==="
docker run -d \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    -p "${PORT}:${PORT}" \
    -e PORT="$PORT" \
    "$IMAGE_NAME"

echo "=== Terminé ! Application disponible sur http://localhost:${PORT} ==="
