#!/usr/bin/env bash
# Preuve du refus des règles de sécurité Firestore (TP 8, partie C), par appels
# directs à l'API REST — donc SANS passer par l'application : c'est
# précisément le scénario d'un client modifié (voir NOTE-SECURITE.md).
#
# Prérequis : Authentication > Email/Password activé dans la console.
# Usage : scripts/prove_rules.sh   (écrit aussi captures/refus-regles-securite.log)
set -u
cd "$(dirname "$0")/.."
PROJECT=$(grep -m1 -o "projectId: '[^']*'" lib/firebase_options.dart | cut -d"'" -f2)
KEY=$(grep -A3 "static const FirebaseOptions android" lib/firebase_options.dart | grep apiKey | cut -d"'" -f2)
FS="https://firestore.googleapis.com/v1/projects/$PROJECT/databases/(default)/documents"
LOG=captures/refus-regles-securite.log
SUFFIX=$(date +%s)

say() { echo "$@" | tee -a "$LOG"; }
: > "$LOG"
say "== Preuve des règles Firestore — projet $PROJECT — $(date -Is) =="

signup() { # $1 = email -> imprime "idToken uid"
  curl -s -X POST "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$KEY" \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"$1\",\"password\":\"secret123\",\"returnSecureToken\":true}" |
    python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("idToken","ERR:"+json.dumps(d)), d.get("localId",""))'
}
status() { python3 -c 'import sys,json; d=json.load(sys.stdin); e=d.get("error"); print(("HTTP %s %s" % (e["code"], e["status"])) if e else "HTTP 200 OK")'; }

read A_TOKEN A_UID < <(signup "proof-a-$SUFFIX@example.com")
read B_TOKEN B_UID < <(signup "proof-b-$SUFFIX@example.com")
case "$A_TOKEN" in ERR:*) say "Création de compte impossible : $A_TOKEN"; exit 1;; esac
say "Organisateur A : $A_UID"
say "Organisateur B : $B_UID"

say; say "1) Lecture NON authentifiée de la collection events"
curl -s "$FS/events" | status | tee -a "$LOG"

say; say "2) A crée un événement dont il est propriétaire (doit réussir)"
DOC=$(curl -s -X POST "$FS/events" -H "Authorization: Bearer $A_TOKEN" -H 'Content-Type: application/json' \
  -d "{\"fields\":{\"title\":{\"stringValue\":\"Événement de A\"},\"ownerId\":{\"stringValue\":\"$A_UID\"}}}")
echo "$DOC" | status | tee -a "$LOG"
DOC_PATH=$(echo "$DOC" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("name",""))')
say "   document : ${DOC_PATH##*/}"

say; say "3) B tente de MODIFIER l'événement de A (doit être refusé)"
curl -s -X PATCH "https://firestore.googleapis.com/v1/$DOC_PATH?updateMask.fieldPaths=title" \
  -H "Authorization: Bearer $B_TOKEN" -H 'Content-Type: application/json' \
  -d '{"fields":{"title":{"stringValue":"piraté par B"}}}' | status | tee -a "$LOG"

say; say "4) B tente de LIRE l'événement de A (doit être refusé)"
curl -s "https://firestore.googleapis.com/v1/$DOC_PATH" -H "Authorization: Bearer $B_TOKEN" | status | tee -a "$LOG"

say; say "5) B tente de créer un événement au nom de A (doit être refusé)"
curl -s -X POST "$FS/events" -H "Authorization: Bearer $B_TOKEN" -H 'Content-Type: application/json' \
  -d "{\"fields\":{\"title\":{\"stringValue\":\"usurpation\"},\"ownerId\":{\"stringValue\":\"$A_UID\"}}}" | status | tee -a "$LOG"

say; say "6) A relit son propre événement (doit réussir)"
curl -s "https://firestore.googleapis.com/v1/$DOC_PATH" -H "Authorization: Bearer $A_TOKEN" | status | tee -a "$LOG"

say; say "Nettoyage : suppression de l'événement et des deux comptes de test"
curl -s -X DELETE "https://firestore.googleapis.com/v1/$DOC_PATH" -H "Authorization: Bearer $A_TOKEN" | status | tee -a "$LOG"
for T in "$A_TOKEN" "$B_TOKEN"; do
  curl -s -o /dev/null -X POST "https://identitytoolkit.googleapis.com/v1/accounts:delete?key=$KEY" \
    -H 'Content-Type: application/json' -d "{\"idToken\":\"$T\"}"
done
