# Allow accessing contents of the config.yaml
CF=/opt/telekinesis/etc/telekinesis.yaml

# Generate a json version
#CF_JSON=/opt/telekinesis/run/telekinesis.json

#cat ${CF} | yq > ${CF_JSON} || {
#   echo "invalid configuration at ${CF}, bailing"
#   exit 1
#}

CF_VAL=""

get_val() {
   CF_VAL=$(cat ${CF} | yq $1)
   # remove outer quotes if present
   temp="${CF_VAL%\"}"
   temp="${temp#\"}"
   CF_VAL="$temp"
   return "$?"
}

get_val ".paths.rootdir"
TKDIR="${CF_VAL}"
