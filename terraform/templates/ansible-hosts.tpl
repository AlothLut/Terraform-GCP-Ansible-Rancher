[master]
${master_ip}

[workers]
%{ for ip in workers_ip ~}
${ip}
%{ endfor ~}

[SERVERS:children]
master
workers

[SERVERS:vars]
ansible_user=${user}
ansible_ssh_private_key_file=${ssh_secret_key}