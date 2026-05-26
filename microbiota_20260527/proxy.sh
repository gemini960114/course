if ! grep -q 'intgpn02-ib:53128' ~/.bashrc; then
  cat <<'EOF' >> ~/.bashrc

# proxy
export http_proxy="http://intgpn02-ib:53128"
export https_proxy="http://intgpn02-ib:53128"
export HTTP_PROXY="$http_proxy"
export HTTPS_PROXY="$https_proxy"
export no_proxy="localhost,127.0.0.1,::1,intgpn02,intgpn02-ib,*.nchc.org,*.niar.org.tw"
export NO_PROXY="$no_proxy"
EOF
else
  echo "Proxy settings already exist in ~/.bashrc, skip."
fi