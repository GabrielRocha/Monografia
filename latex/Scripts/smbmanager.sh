#!/bin/bash
#Gabriel Rocha
end=0
help="É NECESSÁRIO TER PERMISSÃO DE ROOT \nUSO: smbmanager [OPCAO] [VALOR] \n \nOpções gerais:\n -g [VALOR]   Grupo no qual será adicionado a máquina ou usuário  \n -m [VALOR]   Nome da máquina a ser cadastrada \n -u [VALOR]   Usuário a ser cadastrado no sistema e no samba \n -d [VALOR]   Usuário a ser deletado do sistema \n -x [VALOR]   Máquina a ser deletada do samba e do sistema"

AddMachine(){
if [ -n "$machine" ] ; then
    if [ -z "$group" ] ; then
        useradd --disabled-login --home /dev/null --shell /bin/false $machine\$ 2>/dev/null && passwd -l $machine\$ 2>/dev/null && smbpasswd -a -m $machine
    fi
    if [ -n "$group" ]; then
        useradd --disabled-login --home /dev/null --shell /bin/false --group $group $machine\$
	check=$(echo $?)
	if [ $check -eq 0 ]; then
	    passwd -l $machine\$ 2>/dev/null && smbpasswd -a -m $machine 2>/dev/null
	fi
    fi        
fi
}

AddUser(){
if [ -n "$user" ] ; then
    if [ -z "$group" ] ; then
        adduser $user 2>/dev/null
        smbpasswd -a $user
    fi
    if [ -n "$group" ] ; then
        adduser $user 2>/dev/null	
 		usermod -g $group $user
		check=$(echo $?)
	if [ $check -eq 0 ]; then
	    smbpasswd -a $user
	fi	
    fi
fi
}

DelMachine(){
if [ -n "$delmachine" ]; then    
    smbpasswd -x -m $delmachine
    deluser $delmachine\$
fi
}

DelUser(){
if [ -n "$deluser" ]; then    
    smbpasswd -x $deluser
    deluser $deluser
fi
}

while getopts "hg:m:u:d:x:" paramentro;
do
   case $paramentro in
      h) echo -e $help;;
      g) group=$OPTARG ;;
      m) machine=$OPTARG ;;
      u) user=$OPTARG ;;
      d) deluser=$OPTARG ;;
      x) delmachine=$OPTARG ;;
      *) echo -e $help; end=1;;
   esac
done

if [[ "$group" = *"-"* ]] || [[ "$machine" = *"-"* ]] || [[ "$user" = *"-"* ]] || [[ "$deluser" = *"-"* ]] || [[ "$delmachine" = *"-"* ]]; then
    echo -e $help
else
    if [ $end -ne 1 ] ; then
        AddMachine
        AddUser
        DelMachine
        DelUser
    fi
fi
