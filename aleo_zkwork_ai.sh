#!/bin/bash
set -e
set -u

wallet=aleo1cmwe8t76ad5py0spelnj8dyqe7c6v3pk5vhsd3h3tux7jzdmvu9ss5wju4
download=true
##################################################################
## 获取 echo $PS1 | grep -oP '(?<=C\.)\d+' | head -1 的结果
## 并根据结果修改主机名
##################################################################

# 获取主机名编号
new_hostname=$(echo $PS1 | grep -oP '(?<=C\.)\d+' | head -1)

# 如果结果不为空，则修改主机名
if [[ -n "${new_hostname}" ]]; then
    echo "Changing hostname to: C.${new_hostname}"
    
    # 修改当前主机名
    sudo hostnamectl set-hostname "C.${new_hostname}"

    # 确保主机名更改在重启后依然有效
    # 修改 /etc/hostname
    sudo bash -c "echo 'C.${new_hostname}' > /etc/hostname"

    # 修改 /etc/hosts，避免重启时无法解析主机名
    sudo sed -i "s/127\.0\.1\.1.*/127.0.1.1 C.${new_hostname}/" /etc/hosts
fi

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
