#!/usr/bin/env bash
# Cache-bust du build web : ajoute ?v=<version> aux JS sans empreinte
# (flutter_bootstrap.js + main.dart.js). Indispensable car l'app est servie
# SANS service worker (--pwa-strategy=none) et certains navigateurs (surtout
# les navigateurs intégrés WhatsApp/Facebook) gardent un ancien main.dart.js
# en cache -> l'utilisateur exécute du vieux code après une mise à jour.
#
# Usage : bash tools/cachebust.sh [build/web] [version]
set -euo pipefail

DIR="${1:-build/web}"
VER="${2:-$(grep -m1 '^version:' pubspec.yaml | sed 's/version:[[:space:]]*//' | tr '+' '-')}"

echo "Cache-bust $DIR avec v=$VER"

# index.html : versionne le chargement du bootstrap.
sed -i "s#flutter_bootstrap.js\"#flutter_bootstrap.js?v=$VER\"#g" "$DIR/index.html"

# flutter_bootstrap.js : versionne les références à main.dart.js.
sed -i "s#\"main.dart.js\"#\"main.dart.js?v=$VER\"#g" "$DIR/flutter_bootstrap.js"

echo "OK : "
grep -o 'flutter_bootstrap.js?v=[^\"]*' "$DIR/index.html" | head -1
grep -o '"main.dart.js?v=[^\"]*"' "$DIR/flutter_bootstrap.js" | head -1
