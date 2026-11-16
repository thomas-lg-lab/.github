#!/usr/bin/env bash
# The lab's runtime contract test: runs an image the way the lab cluster does (uid 10001, read-only root
# filesystem, /tmp as tmpfs, empty /data and read-only /secrets) and checks what a lab app promises.
# Called by container-image.yml; runs anywhere with Docker, curl and openssl.
#
# Environment:
#   IMAGE           the image to test (required)
#   PROTECTED_PATH  login variant: a path only a signed-in user may read; empty for an app without accounts
#   DATABASE_PATH   database variant: a path that reads the database; empty for an app without one
#   POSTGRES_IMAGE  the PostgreSQL started for the database variant (required with DATABASE_PATH)
set -eu
: "${IMAGE:?}" "${PROTECTED_PATH:=}" "${DATABASE_PATH:=}"
[ -z "$DATABASE_PATH" ] || : "${POSTGRES_IMAGE:?}"

data="" secrets=""
# Leaves nothing behind, so a failed run does not break the next one on the same machine.
cleanup() {
    docker rm -f contract contract-db > /dev/null 2>&1 || true
    docker network rm contract > /dev/null 2>&1 || true
    [ -z "$data$secrets" ] || rm -rf "$data" "$secrets" 2> /dev/null || true
}
trap cleanup EXIT
cleanup

fail() {
    echo "::error title=Runtime contract::$1"
    case "$1" in *" answered 000"* | *" answers 000 "*) echo "000: no answer within 10 s." ;; esac
    if docker inspect contract > /dev/null 2>&1; then docker logs contract 2>&1 | tail -20; fi
    exit 1
}
# code <path> [curl options]: the HTTP status of a GET, 000 when nothing answers.
code() {
    local path=$1
    shift
    curl -s -o /dev/null -m 10 -w '%{http_code}' "$@" "http://127.0.0.1:18080$path" || true
}
start_app() {
    docker run -d --name contract --user 10001:10001 --read-only --tmpfs /tmp \
        -v "$data:/data" -v "$secrets:/secrets:ro" -p 127.0.0.1:18080:8080 "$@" "$IMAGE" > /dev/null
    for _ in $(seq 1 30); do
        [ "$(code /healthz)" = 200 ] && return
        sleep 1
    done
    fail "GET /healthz on 8080 did not answer 200 within 30 s"
}
stop_app() {
    [ -n "$(docker logs contract 2>&1)" ] || fail "nothing logged on stdout or stderr"
    local start status
    start=$(date +%s)
    docker stop -t 10 contract > /dev/null
    took=$(($(date +%s) - start))
    status=$(docker inspect --format '{{.State.ExitCode}}' contract)
    [ "$status" != 137 ] && [ "$took" -lt 10 ] || fail "no clean stop on SIGTERM (exit $status after ${took} s)"
    docker rm contract > /dev/null
}
# Default: the reverse proxy's Remote-User names the user. Login variant: it must name nobody.
check_user() {
    local plain forged
    if [ -z "$PROTECTED_PATH" ]; then
        plain=$(code / -H 'Remote-User: contract-test')
        case "$plain" in 2??) ;; *) fail "GET / with a Remote-User header answered $plain" ;; esac
        summary="$summary, / $plain with Remote-User"
        return
    fi
    plain=$(code "$PROTECTED_PATH")
    forged=$(code "$PROTECTED_PATH" -H 'Remote-User: contract-test' -H 'Remote-Groups: admins' \
        -H 'Remote-Email: contract-test@example.org')
    case "$plain" in 401 | 403 | 3??) ;; *) fail "GET $PROTECTED_PATH without a session answered $plain" ;; esac
    case "$forged" in 401 | 403 | 3??) ;;
        *) fail "GET $PROTECTED_PATH with forged Remote-* headers answered $forged" ;;
    esac
    summary="$summary, $PROTECTED_PATH $plain without a session and $forged with forged Remote-* headers"
}
for path in "$PROTECTED_PATH" "$DATABASE_PATH"; do
    case "$path" in "" | /*) ;; *) fail "a contract path must start with / ('$path')" ;; esac
done
user=$(docker image inspect --format '{{.Config.User}}' "$IMAGE")
case "${user%%:*}" in "" | 0 | root) fail "the image sets no non-root USER (Config.User='$user')" ;; esac
summary="user $user"

# 1. Empty /data, empty /secrets.
data=$(mktemp -d) && secrets=$(mktemp -d) && chmod 0777 "$data" && chmod 0755 "$secrets"
start_app
summary="$summary, /healthz 200"
if [ -z "$DATABASE_PATH" ]; then
    check_user
else
    got=$(code "$DATABASE_PATH")
    case "$got" in 5??) ;; *) fail "GET $DATABASE_PATH with no connection string answered $got, not 5xx" ;; esac
fi
stop_app
summary="$summary, logs on stdout, stopped in ${took} s"

# 2. Database variant: the connection string as the lab mounts it, the database not there yet.
if [ -n "$DATABASE_PATH" ]; then
    docker network create contract > /dev/null
    password=$(openssl rand -hex 16)
    printf 'postgresql://app:%s@contract-db:5432/app' "$password" > "$secrets/database-url"
    chmod 0444 "$secrets/database-url"
    start_app --network contract
    got=$(code "$DATABASE_PATH")
    case "$got" in 5??) ;; *) fail "GET $DATABASE_PATH with an unreachable database answered $got, not 5xx" ;; esac
    [ "$(code /healthz)" = 200 ] || fail "GET /healthz no longer answers 200 once the database was asked for"
    summary="$summary; database unreachable: /healthz 200, $DATABASE_PATH $got"

    # As on the lab: the app's user owns its database and is no superuser.
    docker run -d --name contract-db --network contract -e POSTGRES_PASSWORD="$(openssl rand -hex 16)" \
        "$POSTGRES_IMAGE" > /dev/null
    for _ in $(seq 1 60); do
        docker exec contract-db pg_isready -q -h 127.0.0.1 -U postgres && break
        sleep 1
    done
    docker exec contract-db psql -q -v ON_ERROR_STOP=1 -U postgres \
        -c "CREATE ROLE app LOGIN PASSWORD '$password'" -c "CREATE DATABASE app OWNER app" ||
        fail "the test's PostgreSQL did not start (not the app's fault)"
    start=$(date +%s)
    while got=$(code "$DATABASE_PATH"); do
        case "$got" in 000 | 5??) ;; *) break ;; esac
        [ $(($(date +%s) - start)) -lt 60 ] ||
            fail "GET $DATABASE_PATH still answers $got 60 s after the database came up"
        sleep 1
    done
    summary="$summary; database up: $DATABASE_PATH $got after $(($(date +%s) - start)) s"
    check_user
    stop_app
fi
echo "Runtime contract: $summary."
