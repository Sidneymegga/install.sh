#!/bin/bash

# Instalação de dependências
sudo apt-get update
sudo apt-get install -y python3-pip
sudo pip3 install psutil

# Criação do arquivo logfile.txt
sudo touch /root/logfile.txt

# Permissões necessárias para o arquivo logfile.txt
sudo chmod 644 /root/logfile.txt

# Criação do script de monitoramento
echo "
#!/usr/bin/env python3

import psutil
import os
import datetime
import subprocess
import socket
import time

host = '127.0.0.1'
ports = [80, 8080]
cpu_threshold = 90
journald_threshold = 70
verification_count = 0

LOG_FILE = '/root/logfile.txt'
CLEAN_INTERVAL = 3600  # Limpar o arquivo de log a cada 1 hora

def check_port(port):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(1)
    result = sock.connect_ex((host, port))
    sock.close()
    return result == 0

def restart_proxy():
    global verification_count
    cpu_usage = psutil.cpu_percent()
    journald_cpu_usage = 0
    
    # Verificar o uso do jornald
    for proc in psutil.process_iter(['pid', 'name', 'cpu_percent']):
        if proc.info['name'] == 'systemd-journald':
            journald_cpu_usage = proc.info['cpu_percent']
            break
    
    if cpu_usage > cpu_threshold or journald_cpu_usage > journald_threshold:
        verification_count += 1
        if verification_count == 3:
            for port in ports:
                os.system(f'sudo service proxy-{port} restart')
            current_time = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            log_entry = f'{current_time} - MEGGA CLOUD REINICIANDO PROXY devido ao alto uso de CPU ({cpu_usage:.1f}%) e Journald CPU Usage: ({journald_cpu_usage:.1f}%).'
            with open(LOG_FILE, 'a') as logfile:
                logfile.write(log_entry + '\n')
            print(log_entry)  
            verification_count = 0  # Resetar a contagem após reiniciar
            time.sleep(180)  # Esperar 3 minutos após reiniciar antes de retomar a verificação
    else:
        print(f'CPU Usage: {cpu_usage:.1f}%, Journald CPU Usage: {journald_cpu_usage:.1f}%')

def clean_log_file():
    with open(LOG_FILE, 'w') as logfile:
        logfile.write('')
    print(f'O arquivo de log {LOG_FILE} foi limpo.')

def main():
    global verification_count

    clean_log_file()  # Limpar o arquivo de log inicialmente

    while True:
        restart_proxy()
        time.sleep(5)  # Esperar 5 segundos antes da próxima verificação

        if time.time() % CLEAN_INTERVAL < 5:
            clean_log_file()  # Limpar o arquivo de log a cada hora

if __name__ == '__main__':
    main()
" > /root/monitor_cpu.py

# Permissões necessárias para o script de monitoramento
sudo chmod +x /root/monitor_cpu.py

# Configuração do cron para executar o monitoramento a cada 10 minutos
(crontab -l ; echo "@reboot sleep 120 && /usr/bin/python3 /root/monitor_cpu.py >> /root/logfile.txt 2>&1") | crontab -

echo "Instalação concluída com sucesso!"
