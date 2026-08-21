#!/usr/bin/env bash
# Build a signed production AAB for Google Play.
# Run from repo root: ./scripts/build_google_play.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

KEY_PROPS="android/key.properties"
ENV_PRODUCTION="assets/env/.env.production"
AAB_OUT="build/app/outputs/bundle/productionRelease/app-production-release.aab"

echo "==> Hava Mind — Google Play production AAB"

if ! command -v flutter >/dev/null 2>&1; then
  echo "error: flutter not found in PATH" >&2
  exit 1
fi

if [[ ! -f "$KEY_PROPS" ]]; then
  echo "error: missing $KEY_PROPS — copy from android/key.properties.example" >&2
  exit 1
fi

read_key_prop() {
  local key="$1"
  local line
  line="$(grep -E "^${key}=" "$KEY_PROPS" | head -1 || true)"
  if [[ -z "$line" ]]; then
    return 1
  fi
  printf '%s' "${line#*=}"
}

storePassword="$(read_key_prop storePassword || true)"
keyPassword="$(read_key_prop keyPassword || true)"
keyAlias="$(read_key_prop keyAlias || true)"
storeFile="$(read_key_prop storeFile || true)"

if [[ -z "$storeFile" || -z "$storePassword" || -z "$keyPassword" || -z "$keyAlias" ]]; then
  echo "error: $KEY_PROPS must set storeFile, storePassword, keyPassword, keyAlias" >&2
  exit 1
fi

if [[ "$storeFile" = /* ]]; then
  KEYSTORE_PATH="$storeFile"
else
  KEYSTORE_PATH="android/app/$storeFile"
fi

if [[ ! -f "$KEYSTORE_PATH" ]]; then
  echo "error: keystore not found at $KEYSTORE_PATH" >&2
  echo "       storeFile is relative to android/app (e.g. ../upload-keystore.jks)" >&2
  exit 1
fi

echo "==> Verifying upload keystore credentials..."
if ! keytool -list -v \
  -keystore "$KEYSTORE_PATH" \
  -alias "$keyAlias" \
  -storepass "$storePassword" \
  -keypass "$keyPassword" >/dev/null 2>&1; then
  echo "error: keystore password or alias is wrong — fix android/key.properties" >&2
  echo "       Test manually: keytool -list -v -keystore $KEYSTORE_PATH -alias $keyAlias" >&2
  exit 1
fi

echo "==> Release certificate fingerprints (add to Google Cloud OAuth for com.havamind.app):"
keytool -list -v \
  -keystore "$KEYSTORE_PATH" \
  -alias "$keyAlias" \
  -storepass "$storePassword" \
  -keypass "$keyPassword" 2>/dev/null | grep -E 'SHA1:|SHA256:' || true

if [[ ! -f "$ENV_PRODUCTION" ]]; then
  echo ""
  echo "warning: $ENV_PRODUCTION is missing — build will fall back to assets/env/.env (often dev keys)."
  echo "         For store builds, copy assets/env/.env.example → $ENV_PRODUCTION"
  echo "         and use production Supabase + RevenueCat Android key (goog_...)."
  echo ""
  read -r -p "Continue anyway? [y/N] " ans
  case "$(printf '%s' "$ans" | tr '[:upper:]' '[:lower:]')" in
    y|yes) ;;
    *) exit 1 ;;
  esac
else
  android_rc_key="$(grep -E '^REVENUECAT_API_KEY_ANDROID=' "$ENV_PRODUCTION" | head -1 || true)"
  android_rc_key="${android_rc_key#REVENUECAT_API_KEY_ANDROID=}"
  if [[ "$android_rc_key" != goog_* ]]; then
    echo "error: $ENV_PRODUCTION must set REVENUECAT_API_KEY_ANDROID=goog_... (Play production SDK key)." >&2
    echo "       A test_ key or placeholder will be rejected by store users at purchase time." >&2
    exit 1
  fi
fi

echo "==> Building app bundle (production)..."
flutter build appbundle --flavor production -t lib/main_production.dart

if [[ -f "$AAB_OUT" ]]; then
  echo ""
  echo "OK: $AAB_OUT"
  ls -lh "$AAB_OUT"
else
  echo "error: expected output not found at $AAB_OUT" >&2
  exit 1
fi
