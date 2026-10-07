#!/usr/bin/env bash
# Preuve des règles de sécurité Firestore par appels directs à l'API REST —
# donc SANS passer par l'application : c'est le scénario d'un client modifié,
# que seul le serveur peut arrêter.
#
# Crée deux comptes de test (A et B), déroule les essais, puis supprime tout.
# Usage : scripts/prove_rules.sh   (écrit captures/preuve-regles-securite.log)
set -u
cd "$(dirname "$0")/.."
OPTIONS=lib/data/firebase/firebase_options.dart
PROJECT=$(grep -m1 -o "projectId: '[^']*'" "$OPTIONS" | cut -d"'" -f2)
KEY=$(grep -A3 "static const FirebaseOptions android" "$OPTIONS" | grep apiKey | cut -d"'" -f2)
ROOT="https://firestore.googleapis.com/v1"
FS="$ROOT/projects/$PROJECT/databases/(default)/documents"
LOG=captures/preuve-regles-securite.log
SUFFIX=$(date +%s)

say() { echo "$@" | tee -a "$LOG"; }
: > "$LOG"
say "== Preuve des règles Firestore — projet $PROJECT — $(date -Is) =="

signup() { # $1 = courriel -> imprime "idToken uid"
  curl -s -X POST "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$KEY" \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"$1\",\"password\":\"secret123\",\"returnSecureToken\":true}" |
    python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("idToken","ERR:"+json.dumps(d)), d.get("localId",""))'
}
status() { python3 -c 'import sys,json; d=json.load(sys.stdin); e=d.get("error"); print(("   -> HTTP %s %s" % (e["code"], e["status"])) if e else "   -> HTTP 200 OK")'; }
call() { # $1 = méthode, $2 = URL, $3 = jeton ("" = anonyme), $4 = corps JSON (facultatif)
  local auth=(); [ -n "$3" ] && auth=(-H "Authorization: Bearer $3")
  curl -s -X "$1" "$2" "${auth[@]}" -H 'Content-Type: application/json' ${4:+-d "$4"}
}

read -r A_TOKEN A_UID < <(signup "proof-a-$SUFFIX@example.com")
read -r B_TOKEN B_UID < <(signup "proof-b-$SUFFIX@example.com")
case "$A_TOKEN" in ERR:*) say "Création de compte impossible : $A_TOKEN"; exit 1;; esac
say "Organisateur A : $A_UID"
say "Organisateur B : $B_UID"

say; say "--- Collection events ---"
say "1) Lecture NON authentifiée de la collection (attendu : refus)"
call GET "$FS/events" "" | status | tee -a "$LOG"

say "2) A crée un événement dont il est propriétaire (attendu : succès)"
DOC=$(call POST "$FS/events" "$A_TOKEN" "{\"fields\":{\"title\":{\"stringValue\":\"Événement de A\"},\"ownerId\":{\"stringValue\":\"$A_UID\"},\"capacity\":{\"integerValue\":\"10\"}}}")
echo "$DOC" | status | tee -a "$LOG"
EVENT=$(echo "$DOC" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("name",""))')

say "3) B tente de LIRE l'événement de A (attendu : refus)"
call GET "$ROOT/$EVENT" "$B_TOKEN" | status | tee -a "$LOG"

say "4) B tente de MODIFIER l'événement de A (attendu : refus)"
call PATCH "$ROOT/$EVENT?updateMask.fieldPaths=title" "$B_TOKEN" '{"fields":{"title":{"stringValue":"piraté par B"}}}' | status | tee -a "$LOG"

say "5) B tente de SUPPRIMER l'événement de A (attendu : refus)"
call DELETE "$ROOT/$EVENT" "$B_TOKEN" | status | tee -a "$LOG"

say "6) B tente de créer un événement au nom de A (attendu : refus)"
call POST "$FS/events" "$B_TOKEN" "{\"fields\":{\"title\":{\"stringValue\":\"usurpation\"},\"ownerId\":{\"stringValue\":\"$A_UID\"}}}" | status | tee -a "$LOG"

say "7) A tente de céder son événement à B en changeant ownerId (attendu : refus)"
call PATCH "$ROOT/$EVENT?updateMask.fieldPaths=ownerId" "$A_TOKEN" "{\"fields\":{\"ownerId\":{\"stringValue\":\"$B_UID\"}}}" | status | tee -a "$LOG"

say "8) A modifie son propre événement (attendu : succès)"
call PATCH "$ROOT/$EVENT?updateMask.fieldPaths=title" "$A_TOKEN" '{"fields":{"title":{"stringValue":"Renommé par A"}}}' | status | tee -a "$LOG"

say; say "--- Collection registrations ---"
EMAIL="ada@example.org"
REG_ID="${A_UID}_42_${EMAIL}"
REG_BODY="{\"fields\":{\"userId\":{\"stringValue\":\"$A_UID\"},\"eventId\":{\"stringValue\":\"42\"},\"eventTitle\":{\"stringValue\":\"Test\"},\"participantName\":{\"stringValue\":\"Ada\"},\"participantEmail\":{\"stringValue\":\"$EMAIL\"},\"seats\":{\"integerValue\":\"1\"}}}"

say "9) A confirme une inscription (attendu : succès)"
call POST "$FS/registrations?documentId=$REG_ID" "$A_TOKEN" "$REG_BODY" | status | tee -a "$LOG"

say "10) A réinscrit la MÊME personne au MÊME événement — doublon (attendu : refus)"
call PATCH "$FS/registrations/$REG_ID" "$A_TOKEN" "${REG_BODY/\"1\"/\"2\"}" | status | tee -a "$LOG"

say "11) A tente le même doublon sous un autre identifiant de document (attendu : refus)"
call POST "$FS/registrations?documentId=autre-identifiant-$SUFFIX" "$A_TOKEN" "$REG_BODY" | status | tee -a "$LOG"

say "12) A demande 7 places, au-delà du plafond de 6 (attendu : refus)"
call POST "$FS/registrations?documentId=${A_UID}_43_${EMAIL}" "$A_TOKEN" "$(echo "$REG_BODY" | sed 's/"42"/"43"/; s/"integerValue":"1"/"integerValue":"7"/')" | status | tee -a "$LOG"

say "13) B tente de LIRE l'inscription de A (attendu : refus)"
call GET "$FS/registrations/$REG_ID" "$B_TOKEN" | status | tee -a "$LOG"

say; say "Nettoyage : inscription, événement et comptes de test supprimés"
call DELETE "$FS/registrations/$REG_ID" "$A_TOKEN" | status | tee -a "$LOG"
call DELETE "$ROOT/$EVENT" "$A_TOKEN" | status | tee -a "$LOG"
for T in "$A_TOKEN" "$B_TOKEN"; do
  curl -s -o /dev/null -X POST "https://identitytoolkit.googleapis.com/v1/accounts:delete?key=$KEY" \
    -H 'Content-Type: application/json' -d "{\"idToken\":\"$T\"}"
done
