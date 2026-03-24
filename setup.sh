#!/bin/bash
pip install tensorrt==10.9.0.34 --break-system-packages
pip install gdown --break-system-packages
echo 'export LD_LIBRARY_PATH=/venv/main/lib/python3.12/site-packages/tensorrt_libs:$LD_LIBRARY_PATH' >> ~/.bashrc
export LD_LIBRARY_PATH=/venv/main/lib/python3.12/site-packages/tensorrt_libs:$LD_LIBRARY_PATH
apt-get install -y libzip4 socat
mkdir -p /root/katago && cd /root/katago
wget -q https://github.com/lightvector/KataGo/releases/download/v1.16.4/katago-v1.16.4-trt10.9.0-cuda12.8-linux-x64.zip
unzip -q katago-v1.16.4-trt10.9.0-cuda12.8-linux-x64.zip
./katago --appimage-extract
wget -q https://media.katagotraining.org/uploaded/networks/models/kata1/kata1-b28c512nbt-s12674021632-d5782420041.bin.gz -O /root/katago/model.bin.gz
gdown "https://drive.google.com/uc?id=132Y7pFwrOY1Hkpmpu6QsQe2KvRww6s_I" -O /root/katago/zhizi_b28_muonfd2.bin.gz
/root/katago/squashfs-root/usr/bin/katago genconfig -model /root/katago/model.bin.gz -output /root/katago/default_gtp.cfg
mkdir -p /root/katago/gtp_logs
sed -i 's|^logDir.*|logDir = /root/katago/gtp_logs|' /root/katago/default_gtp.cfg
sed -i 's|^modelFile.*|modelFile = /root/katago/model.bin.gz|' /root/katago/default_gtp.cfg
sed -i 's|^#\s*analysisWideRootNoise.*|analysisWideRootNoise = 0.04|' /root/katago/default_gtp.cfg
sed -i 's|^#\s*dynamicPlayoutDoublingAdvantageCapPerOppLead.*|dynamicPlayoutDoublingAdvantageCapPerOppLead = 0.06|' /root/katago/default_gtp.cfg
sed -i 's|^#\s*playoutDoublingAdvantage.*|playoutDoublingAdvantage = 0.2|' /root/katago/default_gtp.cfg
sed -i 's|^numSearchThreads.*|numSearchThreads = 256|' /root/katago/default_gtp.cfg
sed -i 's|^nnCacheSizePowerOfTwo.*|nnCacheSizePowerOfTwo = 23|' /root/katago/default_gtp.cfg
sed -i 's|^nnMutexPoolSizePowerOfTwo.*|nnMutexPoolSizePowerOfTwo = 19|' /root/katago/default_gtp.cfg
sed -i 's|^nnMaxBatchSize.*|nnMaxBatchSize = 256|' /root/katago/default_gtp.cfg
grep -q "^keepalive" /root/katago/default_gtp.cfg || echo "keepalive = true" >> /root/katago/default_gtp.cfg
/root/katago/squashfs-root/usr/bin/katago genconfig -model /root/katago/zhizi_b28_muonfd2.bin.gz -output /root/katago/zhizi_gtp.cfg
sed -i 's|^logDir.*|logDir = /root/katago/gtp_logs|' /root/katago/zhizi_gtp.cfg
sed -i 's|^modelFile.*|modelFile = /root/katago/zhizi_b28_muonfd2.bin.gz|' /root/katago/zhizi_gtp.cfg
sed -i 's|^#\s*analysisWideRootNoise.*|analysisWideRootNoise = 0.04|' /root/katago/zhizi_gtp.cfg
sed -i 's|^#\s*dynamicPlayoutDoublingAdvantageCapPerOppLead.*|dynamicPlayoutDoublingAdvantageCapPerOppLead = 0.06|' /root/katago/zhizi_gtp.cfg
sed -i 's|^#\s*playoutDoublingAdvantage.*|playoutDoublingAdvantage = 0.2|' /root/katago/zhizi_gtp.cfg
sed -i 's|^numSearchThreads.*|numSearchThreads = 256|' /root/katago/zhizi_gtp.cfg
sed -i 's|^nnCacheSizePowerOfTwo.*|nnCacheSizePowerOfTwo = 23|' /root/katago/zhizi_gtp.cfg
sed -i 's|^nnMutexPoolSizePowerOfTwo.*|nnMutexPoolSizePowerOfTwo = 19|' /root/katago/zhizi_gtp.cfg
sed -i 's|^nnMaxBatchSize.*|nnMaxBatchSize = 256|' /root/katago/zhizi_gtp.cfg
grep -q "^keepalive" /root/katago/zhizi_gtp.cfg || echo "keepalive = true" >> /root/katago/zhizi_gtp.cfg
ssh-keygen -t rsa -b 4096 -f /root/client_key -N ""
cat /root/client_key.pub >> ~/.ssh/authorized_keys
echo 'alias myip="echo IP: $(curl -s ifconfig.me) SSH Port: $VAST_TCP_PORT_22"' >> ~/.bashrc
curl -s ifconfig.me && echo " <- Server IP"
echo "SSH Port: $VAST_TCP_PORT_22"
cat > /root/start_katago.sh << 'STARTEOF'
#!/bin/bash
export LD_LIBRARY_PATH=/venv/main/lib/python3.12/site-packages/tensorrt_libs:$LD_LIBRARY_PATH
echo "Warming up KataGo... please wait"
echo "name" | /root/katago/squashfs-root/usr/bin/katago gtp \
  -config /root/katago/default_gtp.cfg \
  -model /root/katago/model.bin.gz 2>/dev/null
echo "Warmup done! Starting socat..."
socat TCP-LISTEN:15000,fork,reuseaddr,keepalive \
  EXEC:"/root/katago/squashfs-root/usr/bin/katago gtp -config /root/katago/default_gtp.cfg -model /root/katago/model.bin.gz" &
socat TCP-LISTEN:15001,fork,reuseaddr,keepalive \
  EXEC:"/root/katago/squashfs-root/usr/bin/katago gtp -config /root/katago/zhizi_gtp.cfg -model /root/katago/zhizi_b28_muonfd2.bin.gz" &
echo "=============================="
echo "KataGo started!"
echo "Port 15000 (default), 15001 (zhizi)"
echo "Server IP: $(curl -s ifconfig.me)"
echo "SSH Port: $VAST_TCP_PORT_22"
echo "=============================="
STARTEOF
chmod +x /root/start_katago.sh