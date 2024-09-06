#!/bin/bash
## 如果发现退出码为1则停止运行
# set -o errexit
set -e
## 如果发现空的变量则停止运行
# set -o nounset
set -u

wallet=$1
download=${2:-false}

##################################################################
## 如果服务已经存在则先停止
##################################################################
service_name="aleo.service"
if sudo systemctl list-units --full --all | grep -q ${service_name}
then
    sudo systemctl stop ${service_name}
fi


##################################################################
## 下载依赖
##################################################################
if [[ ${download} == "true" ]]
then
    filename="aleo_prover_public_pro_906.zip"
    sudo rm -f /tmp/${filename}
    sudo wget -c -P /tmp https://dls.filecoin.plus/aleo/zkwork/${filename}
    sudo mkdir -p /opt/zk.work
    sudo rm -rf /opt/zk.work/aleo_prover
    sudo mv /tmp/${filename} /opt/zk.work
    cd /opt/zk.work && sudo unzip /opt/zk.work/${filename}
    # sudo mv aleo_prover_public_0905 aleo_prover
    sudo chmod +x /opt/zk.work/
fi


##################################################################
## 注册为服务
##################################################################
sudo bash -c "cat <<EOF > /etc/systemd/system/${service_name}
[Unit]
# 服务名称，可自定义
Description = Aleo
After = network.target syslog.target
Wants = network.target

[Service]
WorkingDirectory=/opt/zk.work/
Type=simple
Restart=always
RestartSec=5
ExecStart=/opt/zk.work/aleo_prover --pool aleo.hk.zk.work:10003 --address ${wallet} --custom_name `hostname`

[Install]
WantedBy = multi-user.target
EOF"

##################################################################
## 启动服务
##################################################################
sudo systemctl daemon-reload
sudo systemctl enable ${service_name}
sudo systemctl start ${service_name}
