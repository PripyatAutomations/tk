#!/bin/bash
cd /opt/telekinesis/ext/google-translate-cli
pip install -r requirements.txt
pip install pyspellchecker
pip install pyinstaller
pyinstaller --onefile translate.py
cp dist/translate /opt/telekinesis/bin/

export GOOGLE_APPLICATION_CREDENTIALS=/opt/telekinesis/etc/gapps.json

# install google cloud SDK, if needed
curl https://sdk.cloud.google.com | bash

gcloud auth application-default print-access-token
