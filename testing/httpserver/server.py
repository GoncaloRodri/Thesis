from flask import Flask, Response
import os

app = Flask(__name__)


@app.route('/bytes/<int:size>')
def random_bytes(size):
    data = os.urandom(size)
    return Response(data, mimetype='application/octet-stream')
