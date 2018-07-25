export API_USER="trex"
export API_PASSWORD="123321"
export API_EMAIL="bugs@antinex.com"
export API_FIRSTNAME="Guest"
export API_LASTNAME="Guest"
export API_URL="https://api.example.com"
export API_VERBOSE="true"
export API_DEBUG="false"

if [[ "${ANTINEX_USER}" != "" ]]; then
    export API_USER="${ANTINEX_USER}"
else
    export ANTINEX_USER="${API_USER}"
fi

if [[ "${ANTINEX_PASSWORD}" != "" ]]; then
    export API_PASSWORD="${ANTINEX_PASSWORD}"
else
    export ANTINEX_PASSWORD="${API_PASSWORD}"
fi

if [[ "${ANTINEX_URL}" != "" ]]; then
    export API_URL="${ANTINEX_URL}"
else
    export ANTINEX_URL="${API_URL}"
fi
if [[ "${ANTINEX_EMAIL}" != "" ]]; then
    export API_EMAIL="${ANTINEX_EMAIL}"
else
    export ANTINEX_EMAIL="${API_EMAIL}"
fi
if [[ "${ANTINEX_FIRSTNAME}" != "" ]]; then
    export API_FIRSTNAME="${ANTINEX_FIRSTNAME}"
else
    export ANTINEX_FIRSTNAME="${API_FIRSTNAME}"
fi
if [[ "${ANTINEX_LASTNAME}" != "" ]]; then
    export API_LASTNAME="${ANTINEX_LASTNAME}"
else
    export ANTINEX_LASTNAME="${API_LASTNAME}"
fi
if [[ "${ANTINEX_VERBOSE}" != "" ]]; then
    export API_VERBOSE="${ANTINEX_VERBOSE}"
else
    export ANTINEX_VERBOSE="${API_VERBOSE}"
fi
if [[ "${ANTINEX_DEBUG}" != "" ]]; then
    export API_DEBUG="${ANTINEX_DEBUG}"
else
    export ANTINEX_DEBUG="${API_DEBUG}"
fi
