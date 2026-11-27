from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/")
def accueil():
    return "<h1>Bonjour depuis Docker !</h1>"

@app.route("/api/taches")
def taches():
    return jsonify(["Apprendre Python", "Apprendre Docker", "Déployer"])

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
