#!/bin/bash

# Instalação de dependências
sudo apt-get update
sudo apt-get install -y python3-pip
sudo pip3 install psutil

# Criação do script de monitoramento
echo '
#!/usr/bin/env python3

import psutil
import os
import datetime
import subprocess
import socket
import time

host = '127.0.0.1'
ports = [80, 8080]
cpu_threshold = 100
journald_threshold = 70
verification_count = 0

def check_port(port):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(1)
    result = sock.connect_ex((host, port))
    sock.close()
    return result == 0

def restart_proxy():
    for port in ports:
        os.system(f'sudo service proxy-{port} restart')
    current_time = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    log_entry = f'{current_time} - MEGGA CLOUD REINICIANDO PROXY POR ALTO USO DE CPU.'
    with open('/root/logfile.txt', 'a') as logfile:
        logfile.write(log_entry + '\n')
    print(log_entry)  

def restart_journald():
    subprocess.run(['sudo', 'systemctl', 'restart', 'systemd-journald'])
    current_time = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    log_entry = f'{current_time} - REINICIANDO JOURNALD DEVIDO AO ALTO USO DE JOURNALD.'
    with open('/root/logfile.txt', 'a') as logfile:
        logfile.write(log_entry + '\n')
    print(log_entry)

def main():
    global verification_count

    while True:
        cpu_usage = psutil.cpu_percent(interval=1)
        journald_cpu_usage = 0

        for proc in psutil.process_iter(['pid', 'name', 'cpu_percent']):
            if proc.info['name'] == 'systemd-journald':
                journald_cpu_usage = proc.info['cpu_percent']
                break

        print(f'CPU Usage: {cpu_usage}')
        print(f'Journald CPU Usage: {journald_cpu_usage}')

        if cpu_usage > cpu_threshold or journald_cpu_usage > journald_threshold:
            verification_count += 1
        else:
            verification_count = 0

        if verification_count == 3:
            if cpu_usage > cpu_threshold:
                restart_proxy()
            if journald_cpu_usage > journald_threshold:
                restart_journald()
            verification_count = 0  # Reseta a contagem após reiniciar

        time.sleep(5)  # Aguarda 1 minuto antes de verificar novamente

if __name__ == '__main__':
    main()
' > /root/monitor_cpu.py

# Permissões necessárias para o script de monitoramento
sudo chmod +x /root/monitor_cpu.py

# Configuração do cron para executar o monitoramento a cada 10 minutos
(crontab -l ; echo "*/10 * * * * /usr/bin/python3 /root/monitor_cpu.py > /dev/null 2>&1") | crontab -
(crontab -l ; echo "@reboot sleep 120 && /usr/bin/python3 /root/monitor_cpu.py >> /root/logfile.txt 2>&1") | crontab -

echo "Instalação concluída com sucesso!"
