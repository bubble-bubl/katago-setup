#!/bin/bash
pip install tensorrt==10.9.0.34
pip install gdown
TENSORRT_PATH=$(find /usr -name "libnvinfer.so.10" 2>/dev/null | head -1 | xargs dirname)
echo "export LD_LIBRARY_PATH=$TENSORRT_PATH:\$LD_LIBRARY_PATH" >> ~/.bashrc
export LD_LIBRARY_PATH=$TENSORRT_PATH:$LD_LIBRARY_PATH
apt-get install -y libzip4 socat unzip libgoogle-perftools-dev
mkdir -p /root/katago && cd /root/katago
wget -q https://github.com/lightvector/KataGo/releases/download/v1.16.4/katago-v1.16.4-trt10.9.0-cuda12.8-linux-x64.zip
unzip -o -q katago-v1.16.4-trt10.9.0-cuda12.8-linux-x64.zip
chmod +x ./katago
./katago --appimage-extract
wget -q https://media.katagotraining.org/uploaded/networks/models/kata1/kata1-b28c512nbt-s12674021632-d5782420041.bin.gz -O /root/katago/model.bin.gz
gdown "https://drive.google.com/uc?id=132Y7pFwrOY1Hkpmpu6QsQe2KvRww6s_I" -O /root/katago/zhizi_b28_muonfd2.bin.gz
mkdir -p /root/katago/gtp_logs
wget -q https://raw.githubusercontent.com/bubble-bubl/katago-setup/main/default_gtp.cfg -O /root/katago/default_gtp.cfg
cp /root/katago/default_gtp.cfg /root/katago/zhizi_gtp.cfg
sed -i 's|^modelFile.*|modelFile = /root/katago/zhizi_b28_muonfd2.bin.gz|' /root/katago/zhizi_gtp.cfg
echo 'alias myip="echo IP: $(curl -s ifconfig.me) SSH Port: $VAST_TCP_PORT_22"' >> ~/.bashrc
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's|#AuthorizedKeysFile.*|AuthorizedKeysFile .ssh/authorized_keys|' /etc/ssh/sshd_config
service ssh restart

TRTPATH=$(find /usr -name "libnvinfer.so.10" 2>/dev/null | head -1 | xargs dirname)

echo "Warming up KataGo default model..."
echo "name" | env LD_LIBRARY_PATH=$TRTPATH /root/katago/squashfs-root/usr/bin/katago gtp \
  -config /root/katago/default_gtp.cfg \
  -model /root/katago/model.bin.gz 2>/dev/null

echo "Warming up KataGo zhizi model..."
echo "name" | env LD_LIBRARY_PATH=$TRTPATH /root/katago/squashfs-root/usr/bin/katago gtp \
  -config /root/katago/zhizi_gtp.cfg \
  -model /root/katago/zhizi_b28_muonfd2.bin.gz 2>/dev/null

echo "Warmup done! Starting socat..."
socat TCP-LISTEN:15000,fork,reuseaddr,keepalive "EXEC:env LD_LIBRARY_PATH=$TRTPATH /root/katago/squashfs-root/usr/bin/katago gtp -config /root/katago/default_gtp.cfg -model /root/katago/model.bin.gz" &
socat TCP-LISTEN:15001,fork,reuseaddr,keepalive "EXEC:env LD_LIBRARY_PATH=$TRTPATH /root/katago/squashfs-root/usr/bin/katago gtp -config /root/katago/zhizi_gtp.cfg -model /root/katago/zhizi_b28_muonfd2.bin.gz" &

curl -s ifconfig.me && echo " <- Server IP"
echo "SSH Port: $VAST_TCP_PORT_22"