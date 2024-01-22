[kafkaclient]
%{ for index, host in kafkaclients ~}
client${index} ansible_host=${host}
%{ endfor ~}

[kafkaserver]
%{ for index, host in kafkaservers ~}
server${index} ansible_host=${host}
%{ endfor ~}

[elasticsearch]
%{ for index, host in elasticsearch ~}
elastic${index} ansible_host=${host}
%{ endfor ~}

