#!/bin/bash
set -e
set -u

wallet=$1
download=${2:-false}

##################################################################
## 下载依赖
##################################################################
if [[ ${download} == "true" ]]
then
    filename="aleo_prover_public_pro_906.zip"
    rm -f /tmp/${filename}
    wget -c -P /tmp https://dls.filecoin.plus/aleo/zkwork/${filename}
    mkdir -p /opt/zk.work
    rm -rf /opt/zk.work/aleo_prover
    mv /tmp/${filename} /opt/zk.work
    cd /opt/zk.work && unzip /opt/zk.work/${filename}
    chmod +x /opt/zk.work/
fi

##################################################################
## 启动服务并监控
##################################################################
while true; do
    echo "Starting Aleo Prover..."
    
    # 启动服务
    /opt/zk.work/aleo_prover --pool aleo.hk.zk.work:10003 --address ${wallet} --custom_name `hostname`
    
    # 检查退出状态码
    if [ $? -eq 1 ]; then
        echo "Service crashed. Restarting in 5 seconds..."
        sleep 5
    else
        echo "Service stopped gracefully."
        exit 0
    fi
done

##################################################################
## 配置开机自启
##################################################################

# 创建 /etc/rc.local 文件，确保存在
if [ ! -f /etc/rc.local ]; then
    sudo touch /etc/rc.local
    sudo chmod +x /etc/rc.local
    sudo bash -c "echo '#!/bin/bash' > /etc/rc.local"
fi

# 检查 rc.local 中是否已经包含服务启动命令，避免重复添加
if ! grep -q "/usr/local/bin/start_service.sh ${wallet} true" /etc/rc.local; then
    echo "Adding startup command to /etc/rc.local"
    sudo bash -c "echo 'bash /usr/local/bin/start_service.sh ${wallet} true' >> /etc/rc.local"
    sudo bash -c "echo 'exit 0' >> /etc/rc.local"
fi
