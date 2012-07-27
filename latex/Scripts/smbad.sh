#!/bin/sh
 
###############################################################################
# Copyright (C) 2011 - Fabio Antonio Ferreira                                 #
# http://fantonio.wordpress.com | fantonios@gmail.com                         #
#                                                                             #
# Este trabalho está licenciado sob uma Licença Creative Commons              #
# Atribuição-Compartilhamento pela mesma Licença 2.5 Brasil. Para ver a copia #
# desta licença, acesse: http://creativecommons.org/licenses/by-sa/2.5/br/    #
# ou envie uma carta para Creative Commons, 171 Second Street, Suite 300,     #
# San Francisco, California 94105, USA.                                       #
#                                                                             #
# Modificações em 27 de Julho de 2012 por Gabriel Rocha (GBR)                 #
# email: gabriel.rocha.gbr@gmail.com                                          #
#                                                                             #
###############################################################################
#
# Versão 1.0
# - Versão original
#
 
# == FUNCOES ==================================================================
USUARIO=`whoami`
if [ "$USUARIO" != "root" ]; then
  echo
  echo "=============================================================================="
  echo " ESTE PROGRAMA PRECISA SER EXECUTADO COM PERMISSOES DE SUPERUSUARIO!          "  
  echo " Abortando...                              "
  echo "=============================================================================="
  echo
  exit 1
fi
 
_HEAD () {
`which clear`
echo "=============================================================================="
echo "          SISTEMA PARA ADICIONAR MAQUINA LINUX AO DOMÍNIO WINDOWS OU LINUX"
echo "=============================================================================="
}
 
_PACOTES () {
        echo "Instalando os pacotes necessários";       
	apt-get install krb5-user libpam-krb5 winbind samba smbfs smbclient krb5-config libkrb53 libkdb5-4 libgssrpc4 -y > /dev/null;
        check=$?
        if [ $check -eq 0 ]; then
           echo "Pacotes instalados com sucesso"
        else
           echo "Falha ao instalar os pacotes"
        fi
}
 
_HORA () {
        echo "Atualizando data e hora";
        ntpdate br.pool.ntp.org > /dev/null;
        echo "Horario atual:" `date`
        echo "Hora alterada com sucesso"
}
 
_BACKUP_ORIG () {
        # Rotina de Backup dos arquivos de configurações.
	if [ ! -e /etc/krb5.conf_backup ]; then
		cp /etc/krb5.conf /etc/krb5.conf_backup > /dev/null;
	fi
	if [ ! -e /etc/resolv.conf_backup ]; then
		cp /etc/resolv.conf /etc/resolv.conf_backup > /dev/null
	fi
	if [ ! -e /etc/samba/smb.conf_backup ]; then
        	cp /etc/samba/smb.conf /etc/samba/smb.conf_backup > /dev/null
	fi
	if [ ! -e /etc/nsswitch.conf_backup ]; then
        	cp /etc/nsswitch.conf /etc/nsswitch.conf_backup > /dev/null
	fi
	if [ ! -e /etc/pam.d/common-account_backup ]; then
	        cp /etc/pam.d/common-account /etc/pam.d/common-account_backup > /dev/null
	fi
	if [ ! -e /etc/pam.d/common-auth_backup ]; then
	        cp /etc/pam.d/common-auth /etc/pam.d/common-auth_backup > /dev/null
	fi
	if [ ! -e /etc/pam.d/common-session_backup ]; then
	        cp /etc/pam.d/common-session /etc/pam.d/common-session_backup > /dev/null
	fi
	if [ ! -e /etc/pam.d/sudo_backup ]; then
	        cp /etc/pam.d/sudo /etc/pam.d/sudo_backup > /dev/null
	fi
         
        check=$(echo $?)
   if [ $check -eq 0 ]; then
      echo "Rotina de Backup executada com sucesso!"
   else
      echo "Falha ao fazer o Backup."
   fi
         
}

_RETURN_BACKUP () {
        # Rotina de Backup dos arquivos de configurações.
        mv /etc/krb5.conf_backup /etc/krb5.conf > /dev/null
	mv /etc/resolv.conf_backup /etc/resolv.conf > /dev/null
        mv /etc/samba/smb.conf_backup /etc/samba/smb.conf > /dev/null
        mv /etc/nsswitch.conf_backup /etc/nsswitch.conf > /dev/null
        mv /etc/pam.d/common-account_backup /etc/pam.d/common-account > /dev/null
        mv /etc/pam.d/common-auth_backup /etc/pam.d/common-auth > /dev/null
        mv /etc/pam.d/common-session_backup /etc/pam.d/common-session > /dev/null
        mv /etc/pam.d/sudo_backup /etc/pam.d/sudo > /dev/null
         
        check=$(echo $?)
   if [ $check -eq 0 ]; then
      echo "Recuperação do Backup executada com sucesso!"
   else
      echo "Falha na recuperação do Backup."
   fi
         
}
 
_NOME_DOMINIO () {
    #Entrada do nome do dominio ao qual deseja engreçar.
	#No caso do linux temos dois servidores um do KDC e outro do dominio
	#No windows informamos o servidor kdc
    read -p "Entre com o nome do Domínio:" var1
    dominio=$(echo $var1 | tr a-z A-Z)
    read -p "Entre com o seu KDC (key Distribution Center):" var2
    kdc=$(echo $var2 | tr A-Z a-z)         
}

_IP_DNS (){
	#IP do servidor de domínio
	read -p "Entre com o IP do servidor de DNS:" ip
	echo "nameserver $ip" > /etc/resolv.conf
}

_SO_SERVIDOR () {
	#SO do AD	
	read -p "Entre com o S.O. do servidor (Linux ou Windows): " so
	so=$(echo $so | tr a-z A-Z)
	workgroup=""
	if [ $so = "LINUX" ] ; then
		read -p "Informe o Domain do Samba4: " workgroup
		workgroup=$(echo $workgroup | tr a-z A-Z)
	else
		workgroup=$(echo $var1)
	fi
}
 
_KRB5 () {
   echo "[libdefaults]
         default_realm = $dominio
 
# The following krb5.conf variables are only for MIT Kerberos.
      krb4_config = /etc/krb.conf
      krb4_realms = /etc/krb.realms
      kdc_timesync = 1
      ccache_type = 4
           forwardable = true
           proxiable = true
 
# The following libdefaults parameters are only for Heimdal Kerberos.
           v4_instance_resolve = false
           v4_name_convert = {
                   host = {
                           rcmd = host
                           ftp = ftp
                   }  
                   plain = {
                           something = something-else
                   }  
           }  
           fcc-mit-ticketflags = true
 
   [realms]
           $dominio = {
                   kdc = $kdc
                   #kdc = $kdc2
                   #kdc = $kdc3
                   admin_server = $kdc
           }  
             
   [domain_realm]
           .$var1 = $kdc
 
   [login]
           krb4_convert = true
           krb4_get_tickets = false" > /etc/krb5.conf
 
   echo "Configuração alterada com sucesso!"
}
 
_TESTEAD () {
   read -p "Entre com um usuário para testar sua conexão com o Active Directory:" user
   kinit $user@$dominio
    
   check=$(echo $?)
   if [ $check -eq 0 ]; then
      echo "Sua máquina conectou com sucesso!"
   else
      echo "Falha ao se conectar com o Active Directory"
   fi
    
}
 
_SMB () {
    
   maquina=$(hostname)
   echo "# Sample configuration file for the Samba suite for Debian GNU/Linux.
   #======================= Global Settings =======================
   [global]
      workgroup = $workgroup
      netbios name = $maquina
      realm = $var1
      server string = %h Server
      dns proxy = no
  	  log file = /var/log/samba/log.%m  
	  max log size = 1000
	  syslog = 0  
      panic action = /usr/share/samba/panic-action %d
      security = ADS
      password server = $kdc
      encrypt passwords = true
      passdb backend = tdbsam
      obey pam restrictions = yes
      unix password sync = yes
      passwd program = /usr/bin/passwd %u
      passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .
      pam password change = yes
      idmap uid = 10000-20000
      winbind gid = 10000-20000
      winbind enum users = yes
      winbind enum groups = yes
      winbind use default domain = yes
      template homedir = /home/%D/%U
      template shell = /bin/bash
 
   [homes]
      comment = Home Directories
      browseable = no
      read only = yes
      create mask = 0700
      directory mask = 0700
      valid users = %S
       
   [printers]
      comment = All Printers
      browseable = no
      path = /var/spool/samba
      printable = yes
      guest ok = no
      read only = yes
      create mask = 0700

   [print$]
      comment = Printer Drivers
      path = /var/lib/samba/printers
      browseable = yes
      read only = yes
      guest ok = no " > /etc/samba/smb.conf
      
   echo "Configuração alterada com sucesso!"
}
 
_FUNC_RESTART() {
        # Stop Winbind
        /etc/init.d/winbind stop > /dev/null
        check=$(echo $?)
   if [ $check -eq 0 ]; then
      echo "Winbind Stop!"
   else
      echo "Falha ao parar o Winbind"
   fi
        # Restart Samba
        /etc/init.d/smbd restart > /dev/null
        check=$(echo $?)
   if [ $check -eq 0 ]; then
      echo "Samba restart com sucesso!"
   else
      echo "Falha no restart do Samba!"
   fi
        # Start Winbind
        /etc/init.d/winbind start > /dev/null
        check=$(echo $?)
   if [ $check -eq 0 ]; then
      echo "Winbind start!"
   else
      echo "Falha ao fazer iniciar o Winbind!"
   fi
}
 
_ADDDOMINIO () {
    
   echo "++++++++++++++++++++++++++++++++++++++++++++"
   echo "++  Adicionando a Máquina no Domínio  ++"
   echo "++++++++++++++++++++++++++++++++++++++++++++"
        # Adicionando a máquina ao domínio
        read -p "Entre com um usuário administrador de Domínio:" user   
   net ads join -U $user;
        check=$(echo $?)
        clear
        # Validação da conexão com o domínio
        if [ $check -eq 0 ]; then
      echo "Sua máquina foi adicionada no Domínio!"
   else
      echo "Falha ao adicionar a máquina no Domínio"
   fi
    
}
 
_TESTDOMINIO () {
        # Teste de requisição ao dominio
        wbinfo -t > /dev/null
        check=$(echo $?)
   if [ $check -eq 0 ]; then
      echo "Teste de Domínio!"
   else
      echo "Falha ao testar o Domínio"
   fi
}
 
_FUNCAUTENTICACAO () {
        # Configurando o arquivo nsswitch.conf
        echo "passwd:         compat winbind
              group:          compat winbind
              shadow:         compat" > /etc/nsswitch.conf
 
        # Teste de configuração do Winbind        
        check=$(echo $?)
   if [ $check -eq 0 ]; then
      echo "Winbind testado com sucesso!"
   else
      echo "Falha ao testar o Winbind"
   fi
        # PAM - common-account
        echo "account sufficient       pam_winbind.so
              account required         pam_unix.so" > /etc/pam.d/common-account
        # PAM - common-auth
        echo "auth sufficient pam_winbind.so
              auth sufficient pam_unix.so nullok_secure use_first_pass
              auth required   pam_deny.so" > /etc/pam.d/common-auth
        # PAM - common-session      
        echo "session required pam_unix.so
              session required pam_mkhomedir.so umask=0022 skel=/etc/skel" > /etc/pam.d/common-session
        # PAM - sudo
        echo "auth sufficient pam_winbind.so
              auth sufficient pam_unix.so use_first_pass
              auth required   pam_deny.so
              @include common-account" > /etc/pam.d/sudo
        # Teste de configuração do PAM
        check=$(echo $?)
   if [ $check -eq 0 ]; then
      echo "PAM configurado com sucesso!"
   else
      echo "Falha ao configurar o PAM"
   fi
 
}
 
_FUNC_HOMEDIR () {
        HOME_DIR=$var1
        if [ -d /home/$HOME_DIR ]; then
                echo "Já existe este diretório !"                
        else
                echo "Este diretório não existe !"
                echo "Criando o diretório $HOME_DIR"
      mkdir /home/$var1
                sleep 2
        fi
}
 
_FUNC_DEL_MAQ_DOMINIO () {
    
   maquina=$(hostname)
        azul="{FONTE}33[0;34m"
        echo "++++++++++++++++++++++++++++++++++++++++++++"
        echo "++  {FONTE}33[0;34m Removendo a Máquina no Domínio  ++"
        echo "++++++++++++++++++++++++++++++++++++++++++++"
       
        # Remover a máquina ao domínio
        read -p "Entre com um usuário administrador de Domínio:" user
   net ads status -U $user
   check1=$(echo $?)   
   clear
   # Validação se a máquina está no domínio
   if [ $check1 -eq 255 ]; then
      echo "A máquina $maquina não está no dominio"
   else
      # Validação de remoção de máquina do domínio
      net ads leave -U $user;
      check=$(echo $?)
      clear
      if [ $check -eq 0 ]; then
         echo "Sua máquina foi removida do Domínio!"
	 _RETURN_BACKUP
      else
         echo "Falha ao remover a máquina no Domínio"
      fi
   fi
 
}
 
 
# =============================================================================
# Menu de seleção
echo "Linux Active Directory:"
echo "(1) Adicionar Máquina no Domínio"
echo "(2) Remover Máquina do Domínio"
echo "(3) Verificar conexão com o Domínio"
echo "(0) Sair"
 
echo "Digite a opção desejada:"
read resposta
 
case "$resposta" in
        1)  
      _HEAD
      _PACOTES
      _HORA
      _BACKUP_ORIG
      _NOME_DOMINIO
      _IP_DNS
      _SO_SERVIDOR
      _KRB5
      _TESTEAD
      _SMB
      _FUNC_RESTART
      _ADDDOMINIO
      _TESTDOMINIO
      _FUNCAUTENTICACAO
      _FUNC_RESTART
      azul="{FONTE}33[0;34m"
      echo "++++++++++++++++++++++++++++++++++++++++++++"
      echo "++ Bem vindo ao dominio $dominio ++"
      echo "++++++++++++++++++++++++++++++++++++++++++++"
  
                ;;  
        2)  
                _FUNC_DEL_MAQ_DOMINIO
                ;;  
        3)  
                _TESTDOMINIO
                ;;  
        0)  
                exit
                ;;  
        *)  
                echo 'Opção Inválida!'
esac
