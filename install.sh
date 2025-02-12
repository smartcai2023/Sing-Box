#!/bin/bash

# 安装Sing-box
echo "正在安装Sing-box..."
bash <(curl -fsSL https://sing-box.app/deb-install.sh)

# 检查Sing-box是否安装成功
if ! command -v sing-box &> /dev/null; then
    echo "Sing-box安装失败，请检查网络连接或手动安装。"
    exit 1
fi

# 创建Sing-box配置文件目录
mkdir -p /etc/sing-box

# 写入配置文件
cat <<EOF > /etc/sing-box/config.json
{
  "log": {
    "level": "info"
  },
  "inbounds": [
    {
      "type": "shadowsocks",
      "listen": "0.0.0.0",
      "listen_port": 8080,
      "sniff": true,
      "network": "tcp",
      "method": "2022-blake3-aes-128-gcm",
      "password": "8JCsPssfgS8tiRwiMlhARg=="
    }
  ],
  "outbounds": [
    {
      "type": "direct"
    },
    {
      "type": "dns",
      "tag": "dns-out"
    }
  ],
  "route": {
    "rules": [
      {
        "protocol": "dns",
        "outbound": "dns-out"
      }
    ]
  }
}
EOF

# 启用并启动Sing-box服务
systemctl enable sing-box
systemctl start sing-box

# 检查Sing-box服务状态
if systemctl is-active --quiet sing-box; then
    echo "Sing-box服务已成功启动。"
else
    echo "Sing-box服务启动失败，请检查配置文件。"
    exit 1
fi

# 安装并启用BBR加速
echo "正在安装并启用BBR加速..."
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p

# 检查BBR是否启用
if sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
    echo "BBR加速已成功启用。"
else
    echo "BBR加速启用失败，请手动检查。"
fi

echo "Sing-box安装和BBR加速配置完成。"
