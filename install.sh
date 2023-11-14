#!/bin/bash

# Instalação de dependências
sudo apt-get update
sudo apt-get install -y python3-pip
sudo pip3 install psutil

# Criação do script de monitoramento
echo "
import psutil
import os
import socket
import datetime

host = '127.0.0.1'
port = 80
cpu_threshold = 70

def check_port():
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(1)
    result = sock.connect_ex((host, port))
    sock.close()
    return result == 0

def restart_proxy():
    os.system('sudo service proxy-80 restart')
    current_time = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    log_entry = f'{current_time} - MEGGA CLOUD REINICIANDO PROXY.'
    with open('/root/logfile.txt', 'a') as logfile:
        logfile.write(log_entry + '\\n')

def main():
    cpu_usage = psutil.cpu_percent(interval=1)
    if cpu_usage > cpu_threshold:
        restart_proxy()
    elif not check_port():
        restart_proxy()

if __name__ == '__main__':
    main()
" > /root/monitor_cpu.py

# Permissões necessárias
sudo chmod +x /root/monitor_cpu.py
sudo touch /root/logfile.txt
sudo chmod 644 /root/logfile.txt

# Configuração do crontab
(crontab -l ; echo "*/3 * * * * nohup /usr/bin/python3 /root/monitor_cpu.py > /dev/null 2>&1 &") | crontab -

echo "Instalação concluída com sucesso!"
