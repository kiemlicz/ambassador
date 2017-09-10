import json
import logging
import os
from logging.handlers import RotatingFileHandler

import salt.config
import yaml
from flask import Flask, render_template, request
from flask_socketio import SocketIO, emit
from requests_oauthlib import OAuth2Session

app = Flask(__name__)
filename = os.path.join(app.root_path, 'file_ext_authorize.conf')
with open(filename) as f:
    config = yaml.load(f.read())
app.config.update(config.items())
socketio = SocketIO(app)

handler = RotatingFileHandler('file_ext_authorize.log', maxBytes=10000, backupCount=1)
handler.setLevel(logging.INFO)
app.logger.addHandler(handler)

salt_config = salt.config.master_config(config['SALT_CONFIG_LOCATION'])


@app.route("/")
def main():
    return render_template('index.html', authorized=False)


@socketio.on("authorize")
def authorize(minion_id):
    try:
        scope = [
            "https://www.googleapis.com/auth/drive.readonly",
            "https://www.googleapis.com/auth/drive.metadata.readonly"
        ]
        redirect_uri = salt_config['gdrive']['redirect_uri']
        authorization_base_url = salt_config['gdrive']['authorization_base_url']
        client_id = salt_config['gdrive']['client_id']
        path = os.path.join(_token_path(minion_id), 'gdrive_token')

        if os.path.exists(path):
            emit('authorized')
        else:
            google = OAuth2Session(client_id, scope=scope, redirect_uri=redirect_uri)
            authorization_url, state = google.authorization_url(authorization_base_url, access_type="offline",
                                                                state=minion_id, approval_prompt="force")
            emit('redirect', authorization_url)
    except Exception as e:
        app.logger.error("Cannot handle authorize request", str(e))
        emit('fail', str(e))


def _token_path(minion_id):
    cache_dir = salt_config['cachedir']
    return os.path.join(cache_dir, "file_ext", minion_id)


@app.route("/authorized")
def authorized():
    try:
        authorization_code = request.args.get('code')
        minion_id = request.args.get('state')
        client_id = salt_config['gdrive']['client_id']
        client_secret = salt_config['gdrive']['client_secret']
        token_url = salt_config['gdrive']['token_url']
        redirect_uri = salt_config['gdrive']['redirect_uri']
        path = _token_path(minion_id)

        google = OAuth2Session(client_id, redirect_uri=redirect_uri)
        token = google.fetch_token(token_url, client_secret=client_secret, code=authorization_code)

        if not os.path.exists(path):
            os.makedirs(path)
        with open(os.path.join(path, 'gdrive_token'), 'w+') as token_file:
            wrapped = {"gdrive": token}
            json.dump(wrapped, token_file)
        return render_template('index.html', authorized=True)
    except Exception as e:
        app.logger.error("Cannot handle authorized response", str(e))
        return render_template('index.html', fail=str(e))
