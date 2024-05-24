# Inclui configurações adicionais que estejam em /etc/ssh/sshd_config.d/
Include /etc/ssh/sshd_config.d/*.conf

# Porta na qual o servidor SSH irá escutar
Port {{SSH_PORT}}

# Habilita autenticação via chave pública
PubkeyAuthentication yes

# Desativa autenticação por senha (exige chave)
PasswordAuthentication no

# Proíbe login direto como root
PermitRootLogin no

# Restringe acesso SSH somente ao usuário especificado
AllowUsers {{SSH_USER}}

# Escuta conexões em todas as interfaces IPv4
ListenAddress 0.0.0.0

# Arquivo padrão onde as chaves públicas autorizadas estão localizadas (relativo ao home do usuário)
AuthorizedKeysFile .ssh/authorized_keys

# Desativa autenticação interativa por teclado
KbdInteractiveAuthentication no

# Habilita PAM para autenticação e políticas adicionais
UsePAM yes

# Permite redirecionamento de aplicações gráficas via SSH (X11 forwarding)
X11Forwarding yes

# Não exibe a mensagem padrão do dia ao conectar via SSH
PrintMotd no

# Permite que variáveis de ambiente do cliente, como LANG e LC_*, sejam aceitas pelo servidor
AcceptEnv LANG LC_*

# Define o subsistema para conexões SFTP
Subsystem sftp /usr/lib/openssh/sftp-server

# Intervalo em segundos para enviar pacotes de keep-alive ao cliente (evita desconexões)
ClientAliveInterval 120
