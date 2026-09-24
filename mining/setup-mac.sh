#!/usr/bin/env bash
# Sets up XMRig on a Mac to mine Monero (XMR) through the SupportXMR pool.
#
# Usage:
#   bash setup-mac.sh                      # asks for your wallet address
#   bash setup-mac.sh YOUR_WALLET_ADDRESS
#
# What it does:
#   1. Downloads the latest official XMRig release for your Mac (Apple Silicon or Intel)
#      from github.com/xmrig/xmrig.
#   2. Checks the download against the SHA256 checksums published with that release.
#   3. Installs it into ~/xmrig-miner.
#   4. Writes ~/xmrig-miner/start-mining.sh, which mines to your wallet using about
#      half your CPU.

set -euo pipefail

INSTALL_DIR="$HOME/xmrig-miner"
POOL="pool.supportxmr.com:443"
CPU_PERCENT=50
WORKER_NAME="$(scutil --get ComputerName 2>/dev/null | tr -cd '[:alnum:]-' || true)"
WORKER_NAME="${WORKER_NAME:-laptop1}"

die() { echo "Error: $*" >&2; exit 1; }

[[ "$(uname -s)" == "Darwin" ]] || die "this script is for macOS."

# --- Wallet address ---------------------------------------------------------
WALLET="${1:-}"
if [[ -z "$WALLET" ]]; then
  echo "Paste your Monero wallet address (starts with 4 or 8), then press Enter:"
  read -r WALLET
fi
WALLET="$(echo "$WALLET" | tr -d '[:space:]')"
# Standard addresses are 95 characters; integrated addresses are 106.
if ! [[ "$WALLET" =~ ^[48][1-9A-HJ-NP-Za-km-z]{94}$ || "$WALLET" =~ ^4[1-9A-HJ-NP-Za-km-z]{105}$ ]]; then
  die "that doesn't look like a Monero address. It should start with 4 or 8 and be 95 characters long."
fi

# --- Pick the right build ---------------------------------------------------
case "$(uname -m)" in
  arm64)  ARCH_PATTERN="macos-arm64" ;;
  x86_64) ARCH_PATTERN="macos-x64" ;;
  *)      die "unsupported processor type: $(uname -m)" ;;
esac

echo "Looking up the latest XMRig release..."
RELEASE_JSON="$(curl -fsSL https://api.github.com/repos/xmrig/xmrig/releases/latest)" \
  || die "couldn't reach GitHub. Check your internet connection."

asset_url() {
  echo "$RELEASE_JSON" | grep -o '"browser_download_url": *"[^"]*"' \
    | sed 's/.*"\(https[^"]*\)"/\1/' | grep -E "$1" | head -n 1
}
TARBALL_URL="$(asset_url "${ARCH_PATTERN}\.tar\.gz$")"
SUMS_URL="$(asset_url "/SHA256SUMS$")"
[[ -n "$TARBALL_URL" ]] || die "couldn't find a ${ARCH_PATTERN} build in the latest release."
[[ -n "$SUMS_URL" ]]    || die "couldn't find the SHA256SUMS file in the latest release."
TARBALL="$(basename "$TARBALL_URL")"

# --- Download and verify ----------------------------------------------------
mkdir -p "$INSTALL_DIR"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Downloading $TARBALL..."
curl -fsSL -o "$TMP/$TARBALL" "$TARBALL_URL"
curl -fsSL -o "$TMP/SHA256SUMS" "$SUMS_URL"

echo "Checking the download is genuine..."
EXPECTED="$(grep " \*\?${TARBALL}\$" "$TMP/SHA256SUMS" | awk '{print $1}' | head -n 1)"
[[ -n "$EXPECTED" ]] || die "no checksum listed for $TARBALL."
ACTUAL="$(shasum -a 256 "$TMP/$TARBALL" | awk '{print $1}')"
[[ "$EXPECTED" == "$ACTUAL" ]] || die "checksum mismatch; the download may be corrupted or tampered with. Nothing was installed."
echo "Checksum OK."

# --- Install ----------------------------------------------------------------
tar -xzf "$TMP/$TARBALL" -C "$TMP"
XMRIG_BIN="$(find "$TMP" -type f -name xmrig -perm -u+x | head -n 1)"
[[ -n "$XMRIG_BIN" ]] || die "couldn't find the xmrig program inside the download."
cp "$XMRIG_BIN" "$INSTALL_DIR/xmrig"
chmod +x "$INSTALL_DIR/xmrig"
# XMRig isn't signed by Apple, so macOS would otherwise refuse to open it.
xattr -d com.apple.quarantine "$INSTALL_DIR/xmrig" 2>/dev/null || true

cat > "$INSTALL_DIR/start-mining.sh" <<START
#!/usr/bin/env bash
# Starts mining Monero. Press Ctrl+C to stop.
# To use more or less of your CPU, change --cpu-max-threads-hint (percent of threads).
cd "\$(dirname "\$0")"
exec ./xmrig \\
  -o $POOL --tls -k \\
  -u $WALLET \\
  -p $WORKER_NAME \\
  --cpu-max-threads-hint=$CPU_PERCENT
START
chmod +x "$INSTALL_DIR/start-mining.sh"

echo
echo "Done. XMRig is installed in $INSTALL_DIR"
echo
echo "To start mining:   $INSTALL_DIR/start-mining.sh"
echo "To stop:           press Ctrl+C in that Terminal window"
echo "Check earnings at: https://supportxmr.com (paste your wallet address)"
echo
read -r -p "Start mining now? [y/N] " ANSWER
if [[ "$ANSWER" =~ ^[Yy]$ ]]; then
  exec "$INSTALL_DIR/start-mining.sh"
fi
