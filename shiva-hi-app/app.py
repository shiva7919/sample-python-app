from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello():
    return "hi from shiva .."

if __name__ == "__main__":
    # used for local dev; Docker image runs gunicorn
    app.run(host="0.0.0.0", port=8000)
