#!/usr/bin/env bash
# =========================================
# WSL2 Proxy config (use default gateway)
# =========================================

PROXY_PORT="7890"

# Windows Host IP = WSL 默认网关
HOST_IP=$(ip route | awk '/^default/ {print $3; exit}')

HTTP_PROXY="http://${HOST_IP}:${PROXY_PORT}"
SOCKS_PROXY="socks5://${HOST_IP}:${PROXY_PORT}"

proxy_on() {
  export http_proxy="$HTTP_PROXY"
  export https_proxy="$HTTP_PROXY"
  export HTTP_PROXY="$HTTP_PROXY"
  export HTTPS_PROXY="$HTTP_PROXY"

  export all_proxy="$SOCKS_PROXY"
  export ALL_PROXY="$SOCKS_PROXY"

  export no_proxy="localhost,127.0.0.1,::1"
  export NO_PROXY="$no_proxy"

  echo "✅ Proxy enabled: $HTTP_PROXY"
}

proxy_off() {
  unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
  unset all_proxy ALL_PROXY
  unset no_proxy NO_PROXY
  echo "❌ Proxy disabled"
}

proxy_status() {
  if [[ -n "$http_proxy" ]]; then
    echo "🟢 Proxy ON  -> $http_proxy"
  else
    echo "🔴 Proxy OFF"
  fi
}


proxy_on

#
git_proxy_on() {
  git config --global http.proxy  "$HTTP_PROXY"
  git config --global https.proxy "$HTTP_PROXY"
  echo "✅ Git proxy enabled (global): $HTTP_PROXY"
}

git_proxy_off() {
  git config --global --unset http.proxy  2>/dev/null || true
  git config --global --unset https.proxy 2>/dev/null || true
  echo "❌ Git proxy disabled (global)"
}

git_proxy_status() {
  echo "http.proxy  = $(git config --global --get http.proxy  || echo '<unset>')"
  echo "https.proxy = $(git config --global --get https.proxy || echo '<unset>')"
}

# 写入 ~/.condarc，兼容 conda config
conda_proxy_on() {
  mkdir -p "$HOME"
  cat > "$HOME/.condarc" <<EOC
proxy_servers:
  http: $HTTP_PROXY
  https: $HTTP_PROXY
EOC
  echo "✅ Conda proxy enabled (~/.condarc): $HTTP_PROXY"
}

conda_proxy_off() {
  # 只移除 proxy_servers 段：简单做法是直接删掉 .condarc
  # 如果你 .condarc 里还有其它配置，不想删，告诉我我给你做“只删代理段”的版本
  rm -f "$HOME/.condarc"
  echo "❌ Conda proxy disabled (removed ~/.condarc)"
}

conda_proxy_status() {
  if [[ -f "$HOME/.condarc" ]]; then
    echo "🟢 ~/.condarc exists:"
    sed -n '1,120p' "$HOME/.condarc"
  else
    echo "🔴 ~/.condarc not found"
  fi
}

proxy_check() {
  echo "========== Proxy Check =========="

  echo "[ENV]"
  echo "http_proxy  = ${http_proxy:-<unset>}"
  echo "https_proxy = ${https_proxy:-<unset>}"
  echo "all_proxy   = ${all_proxy:-<unset>}"
  echo

  echo "[Git global config]"
  if command -v git >/dev/null 2>&1; then
    echo "http.proxy  = $(git config --global --get http.proxy  || echo '<unset>')"
    echo "https.proxy = $(git config --global --get https.proxy || echo '<unset>')"
  else
    echo "git not found"
  fi
  echo

  echo "[Conda]"
  if command -v conda >/dev/null 2>&1; then
    echo "conda proxy_servers:"
    conda config --show proxy_servers 2>/dev/null | sed -n '1,80p'
  else
    echo "conda not found"
  fi
  echo

  echo "[npm]"
  if command -v npm >/dev/null 2>&1; then
    echo "npm proxy      = $(npm config get proxy 2>/dev/null || echo '<err>')"
    echo "npm https-proxy = $(npm config get https-proxy 2>/dev/null || echo '<err>')"
  else
    echo "npm not found"
  fi

  echo "================================="
}

# 可选：让 npm 也写入自身配置（不是必须，env 通常已够用）
npm_proxy_on() {
  if [[ -z "${HTTP_PROXY:-}" ]]; then
    echo "HTTP_PROXY not set. Run proxy_on first."
    return 1
  fi
  npm config set proxy "$HTTP_PROXY"
  npm config set https-proxy "$HTTP_PROXY"
  echo "✅ npm proxy enabled: $HTTP_PROXY"
}

npm_proxy_off() {
  npm config delete proxy 2>/dev/null || true
  npm config delete https-proxy 2>/dev/null || true
  echo "❌ npm proxy disabled (npm config)"
}
