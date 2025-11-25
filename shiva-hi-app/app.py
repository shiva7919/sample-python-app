from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello():
    return "hi from shiva .."

if __name__ == "__main__":
    # Only used when running locally (not in Docker with gunicorn)
    app.run(host="0.0.0.0", port=8000)
