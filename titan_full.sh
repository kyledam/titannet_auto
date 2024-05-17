#!/bin/bash
rm -f titan_full.sh
RED="31m"
GREEN="32m"
YELLOW="33m"
BLUE="34m"
SKYBLUE="36m"
FUCHSIA="35m"

colorEcho() {
    COLOR=$1
    echo -e "\033[${COLOR}${@:2}\033[0m"
}

titan_amd64_url=https://github.com/Titannet-dao/titan-node/releases/download/v0.1.18/titan_v0.1.18_linux_amd64.tar.gz
titan_arm_url=https://gitee.com/blockchain-tools/titan-tools/releases/download/0.1.18/titan_v0.1.18_linux_arm.tar.gz
titan_arm64_url=https://gitee.com/blockchain-tools/titan-tools/releases/download/0.1.18/titan_v0.1.18_linux_arm64.tar.gz

init_system() {
    # Disable selinux
    echo "System initialization"
    if [ -f "/etc/selinux/config" ]; then
        sed -i 's/\(SELINUX=\).*/\1disabled/g' /etc/selinux/config
        setenforce 0 >/dev/null 2>&1
    fi

    echo "net.ipv4.ip_forward = 1" >>/etc/sysctl.conf
    echo "net.core.netdev_max_backlog = 50000" >>/etc/sysctl.conf
    echo "net.ipv4.tcp_max_syn_backlog = 8192" >>/etc/sysctl.conf
    echo "net.core.somaxconn = 50000" >>/etc/sysctl.conf
    echo "net.ipv4.tcp_syncookies = 1" >>/etc/sysctl.conf
    echo "net.ipv4.tcp_tw_reuse = 1" >>/etc/sysctl.conf
    echo "net.ipv4.tcp_tw_recycle = 1" >>/etc/sysctl.conf
    echo "net.ipv4.tcp_keepalive_time = 1800" >>/etc/sysctl.conf
    sysctl -p >/dev/null 2>&1

    # Disable firewalld, ufw
    systemctl stop firewalld >/dev/null 2>&1
    systemctl disable firewalld >/dev/null 2>&1
    systemctl stop ufw >/dev/null 2>&1
    systemctl disable ufw >/dev/null 2>&1
    colorEcho $GREEN "selinux, sysctl.conf, firewall settings completed."
}

change_limit() {
    colorEcho $BLUE "Modifying maximum system connections"
    ulimit -n 65535
    changeLimit="n"

    if [ $(grep -c "root soft nofile" /etc/security/limits.conf) -eq '0' ]; then
        echo "root soft nofile 65535" >>/etc/security/limits.conf
        echo "* soft nofile 65535" >>/etc/security/limits.conf
        changeLimit="y"
    fi

    if [ $(grep -c "root hard nofile" /etc/security/limits.conf) -eq '0' ]; then
        echo "root hard nofile 65535" >>/etc/security/limits.conf
        echo "* hard nofile 65535" >>/etc/security/limits.conf
        changeLimit="y"
    fi

    if [ $(grep -c "DefaultLimitNOFILE=65535" /etc/systemd/user.conf) -eq '0' ]; then
        echo "DefaultLimitNOFILE=65535" >>/etc/systemd/user.conf
        changeLimit="y"
    fi

    if [ $(grep -c "DefaultLimitNOFILE=65535" /etc/systemd/system.conf) -eq '0' ]; then
        echo "DefaultLimitNOFILE=65535" >>/etc/systemd/system.conf
        changeLimit="y"
    fi

    if [[ "$changeLimit" = "y" ]]; then
        echo "Connection limit has been changed to 65535, will take effect after restarting the server"
    else
        echo -n "Current connection limit:"
        ulimit -n
    fi
    colorEcho $GREEN "Maximum connection limit has been modified!"
}

user_add() {
    for i in $(seq $node_number);do
       useradd admin$i
       [ ! -d /home/admin$i ] && mkdir -p /home/admin$i
       chown -R admin$i:admin$i /home/admin$i
    done
}

download_file() {
    cmd=apt
    if [[ $(command -v yum) ]]; then
        cmd=yum
    fi
    if [[ ! $(command -v wget) && ! $(command -v curl) ]]; then
        $cmd update -y
        $cmd -y install wget
        $cmd -y install curl
    fi
    if [[ $(command -v wget) ]]; then
        rm -rf ./titan*
        wget $1
    elif [[ $(command -v curl) ]]; then
        rm -rf ./titan*
        curl -o titan.tar.gz $1
    else
        echo "Please install wget or curl command first!"
        exit 1
    fi
    tar -zxf titan*.gz
    rm -rf ./titan*.gz
    mv $(ls -d titan*)/* /usr/bin
    rm -rf /usr/local/bin/titan* #Remove old executable file directory
}

service_install() {
    for i in $(seq $node_number);do
	cat >/etc/systemd/system/titan$i.service <<-EOF
	[Unit]  
	Description=My Custom Service  
	After=network.target  
  
	[Service]  
	ExecStart=titan-edge daemon start --init --url https://test-locator.titannet.io:5000/rpc/v0
	Restart=always  
	User=admin$i  
	Group=admin$i
  
	[Install]  
	WantedBy=multi-user.target
	EOF
        systemctl daemon-reload
        systemctl enable --now titan${i}.service
        while true;do
            if [ -f /home/admin$i/.titanedge/config.toml ];then
                sed -i "/^\ \ #ListenAddress/c \ \ ListenAddress\ \=\ \"0.0.0.0:123$i\"" /home/admin$i/.titanedge/config.toml
                sed -i "/^\ \ #StorageGB/c \ \ StorageGB\ \=\ ${storagegb}" /home/admin$i/.titanedge/config.toml
                systemctl restart titan${i}.service
                s=0
                while true;do
                    sleep 5
                    sudo -u admin${i} titan-edge state  >/dev/null 2>&1
                    if [ $? -ne 0 ];then
                        if [ $s -lt 10 ];then
                            let s=$s+5
                            continue
                        else
                            s=0
                            systemctl restart titan${i}.service
                            continue
                        fi
                     else
                        break
                    fi
                done
                sudo -u admin$i titan-edge bind --hash=$id https://api-test1.container1.titannet.io/api/v2/device/binding
                break
            else
               systemctl restart titan${i}.service
            fi
            sleep 5
        done
    done
}

install_app(){
    
 
    download_url=$titan_amd64_url
    
    read -p "$(echo -e "Please enter the number of nodes to install:|Please enter the number of nodes:")" node_number
    read -p "$(echo -e "Please enter your ID:|Please enter your id:")" id
    read -p "$(echo -e "Please enter the storage capacity (GB) for each node:|Please enter storage GB:")" storagegb
    init_system
    change_limit
    user_add
    download_file $download_url
    service_install
    monitor_install
}

update_app() {
    colorEcho ${BLUE} "###  Please select CPU architecture type, enter the number and press enter to continue ###"
    colorEcho ${GREEN} "--------------------------------------------"
    echo "1 → x86_64/amd64 architecture"
    colorEcho ${GREEN} "--------------------------------------------"
    echo "2 → armv7/arm32 architecture"
    colorEcho ${GREEN} "--------------------------------------------"
    echo "3 → armv8/arm64 architecture"   
    colorEcho ${GREEN} "--------------------------------------------"
    colorEcho ${BLUE} "###  Please enter the operation number and press enter to continue, or press Ctrl+C to exit this program ###"
    read -p "$(echo -e "Please select CPU architecture [1-3]:|choose[1-3]:")" choose
    case $choose in
    1)
        download_url=$titan_amd64_url
        ;;
    2)
        download_url=$titan_arm_url
        ;;
    3)
        download_url=$titan_arm64_url
        ;;
    *)
        echo "Invalid input, please select again"
        ;;
    esac
    download_file $download_url
    restart_app
    colorEcho ${BLUE} "Update successful! update success"
}

monitor_install() {
cat >/usr/local/bin/titan-monitor.sh <<EOF
#!/bin/bash
while true;do
  for i in {1..5};do
    if [ -f /etc/systemd/system/titan\$i.service ];then
      state=\$(sudo -u admin\$i titan-edge state)
      if [ \$? -ne 0 ];then
        systemctl restart titan\$i
      fi
      state=\${state%\}*}
      state=\${state##*:}
      if [ \${state}1 = "false1" ];then
        systemctl restart titan\$i
      fi
    fi
  done
  sleep 20
done
EOF

cat >/etc/systemd/system/titan-monitor.service <<EOF
[Unit]  
Description=Titan Monitor Service  
After=network.target  
  
[Service]  
ExecStart=/usr/local/bin/titan-monitor.sh
Restart=always  
User=root
Group=root
  
[Install]  
WantedBy=multi-user.target
EOF

chmod +x /usr/local/bin/titan-monitor.sh
systemctl daemon-reload
systemctl enable --now titan-monitor.service
colorEcho ${GREEN} "Monitor installation successful!"
}

restart_app(){
    for i in {1..5};do
        systemctl restart titan$i    
    done     
    colorEcho ${GREEN} "Service restart completed|server restarted"
}

stop_app(){
    for i in {1..5};do
        systemctl stop titan$i
    done
    systemctl stop titan-monitor
    colorEcho ${GREEN} "Service has been stopped|server stoped"
}

main() {
    colorEcho ${GREEN} "--------------------------------------------"
    colorEcho ${GREEN} "######### Welcome to use the tool produced by Moshin Xuwei #########"
    colorEcho ${GREEN} "--------------------------------------------"
    echo "1 → Install node - install node"
    colorEcho ${GREEN} "--------------------------------------------"
    echo "2 → Uninstall node - uninstall node"
    colorEcho ${GREEN} "--------------------------------------------"
    echo "3 → Check node - check node"
    colorEcho ${GREEN} "--------------------------------------------"
    echo "4 → Modify storage - change storage limit"
    colorEcho ${GREEN} "--------------------------------------------"
    echo "5 → Restart node - restart node"
    colorEcho ${GREEN} "--------------------------------------------"
    echo "6 → Monitor and check - monitor and check"
    colorEcho ${GREEN} "--------------------------------------------"
    echo "7 → Update version - update version"
    colorEcho ${GREEN} "--------------------------------------------"
    colorEcho ${YELLOW} "###  Please enter the operation number and press enter to continue, or press Ctrl+C to exit this program ###"
    colorEcho ${YELLOW} "###  please choose number and press enter,or Ctrl+C  exit  ###"
    colorEcho ${GREEN} "--------------------------------------------"

    read -p "$(echo -e "Please choose [1-7]:|choose[1-7]:")" choose

    case $choose in
    1)
        install_app
        ;;
    2)
        uninstall_app
        ;;
    3)
        restart_app
        ;;
    4)
        stop_app
        ;;
    5)
        restart_app
        ;;
    6)
        monitor_install
        ;;
    7)
        update_app
        ;;
    *)
        echo "Feature pending completion, please choose another option."
        ;;
    esac
}

main
