#!/bin/bash
. /opt/telekinesis/lib/config.sh

cd ${TKDIR}/ext/google-translate-cli
pip install -r requirements.txt
pip install pyspellchecker
pip install pyinstaller
pyinstaller --onefile translate.py
cp dist/translate ${TKDIR}/bin/

export GOOGLE_APPLICATION_CREDENTIALS=${TKDIR}/etc/gapps.json

# install google cloud SDK, if needed
curl https://sdk.cloud.google.com | bash

gcloud auth application-default print-access-token
