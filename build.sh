#!/bin/bash
cp ext/Chroma-Hash/jquery.chroma-hash.js www/js
cp src/escapes.js/escapes.js www/js
cp src/escapes.js/escapes.min.js www/js
cp src/toastr/build/toastr.js.map www/js
cp src/toastr/build/toastr.min.js www/js
cp src/toastr/build/toastr.min.css www/css
mkdir -p log/asterisk
mkdir -p var/run/asterisk
mkdir -p var/cron
