#!/usr/bin/env bash
#
# Sobe um build novo para a TestFlight.
#
#   ./tools/ship.sh          # incrementa o build atual em 1
#   ./tools/ship.sh 42       # usa 42 como build
#
# O número do build mora no project.yml (CURRENT_PROJECT_VERSION), então
# subir ele e regerar o projeto é o que faz o Xcode enxergar a mudança.
#
# Autenticação: se existir uma chave da App Store Connect API nas variáveis
# abaixo, ela é usada (não abre janela, serve para rodar sem ninguém olhando).
# Sem elas, o xcodebuild cai na conta que já está logada no Xcode.
#
#   export ASC_KEY_ID=XXXXXXXXXX
#   export ASC_ISSUER_ID=aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee
#   export ASC_KEY_PATH=~/private_keys/AuthKey_XXXXXXXXXX.p8
#
set -euo pipefail

cd "$(dirname "$0")/.."

SCHEME="Lume"
PROJECT="Lume.xcodeproj"
BUILD_DIR="build"
ARCHIVE="$BUILD_DIR/Lume.xcarchive"
OPTIONS="$BUILD_DIR/ExportOptions.plist"

step() { printf '\n\033[1;35m▸ %s\033[0m\n' "$1"; }
fail() { printf '\n\033[1;31m✗ %s\033[0m\n' "$1" >&2; exit 1; }

command -v xcodegen >/dev/null || fail "xcodegen não encontrado — brew install xcodegen"

# ---------------------------------------------------------------- bump
current=$(grep -E '^[[:space:]]+CURRENT_PROJECT_VERSION:' project.yml \
          | head -1 | sed -E 's/.*"([0-9]+)".*/\1/')
[ -n "$current" ] || fail "não consegui ler CURRENT_PROJECT_VERSION do project.yml"
next="${1:-$((current + 1))}"

marketing=$(grep -E '^[[:space:]]+MARKETING_VERSION:' project.yml \
            | head -1 | sed -E 's/.*"([^"]+)".*/\1/')

step "build $current → $next  (versão $marketing)"
# sed do macOS exige o argumento vazio depois do -i
sed -i '' -E "s/(CURRENT_PROJECT_VERSION: )\"$current\"/\1\"$next\"/" project.yml
grep -qE "CURRENT_PROJECT_VERSION: \"$next\"" project.yml || fail "o bump não pegou no project.yml"

# ------------------------------------------------------------ generate
step "xcodegen generate"
xcodegen generate

# ------------------------------------------------------------- archive
step "arquivando (Release)"
rm -rf "$ARCHIVE"
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates \
  | grep -E "error:|warning: .*deprecated|\*\* ARCHIVE" || true

[ -d "$ARCHIVE" ] || fail "o archive não foi criado — rode o comando sem o filtro para ver o log inteiro"

# -------------------------------------------------------------- upload
cat > "$OPTIONS" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store-connect</string>
	<key>destination</key>
	<string>upload</string>
	<key>teamID</key>
	<string>R573HPN65Q</string>
	<key>uploadSymbols</key>
	<true/>
</dict>
</plist>
PLIST

auth=()
if [ -n "${ASC_KEY_ID:-}" ] && [ -n "${ASC_ISSUER_ID:-}" ] && [ -n "${ASC_KEY_PATH:-}" ]; then
  auth=(-authenticationKeyID "$ASC_KEY_ID"
        -authenticationKeyIssuerID "$ASC_ISSUER_ID"
        -authenticationKeyPath "${ASC_KEY_PATH/#\~/$HOME}")
  step "enviando (chave da API)"
else
  step "enviando (conta logada no Xcode)"
fi

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportOptionsPlist "$OPTIONS" \
  -exportPath "$BUILD_DIR/export" \
  -allowProvisioningUpdates \
  "${auth[@]}"

step "build $next enviado"
echo "Leva alguns minutos processando antes de aparecer na TestFlight."
echo "Não esqueça de commitar o bump:  git commit -am \"Build $next\""
