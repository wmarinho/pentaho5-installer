#!/bin/bash

echo "##########################################################"
echo "################  CONFIGURAÇÃO LDAP ######################"
echo "##########################################################"

#set -x

account_name="username"
install_dir="/opt/pentaho"
pentaho_dir="$install_dir/biserver-ce"
PWD=`pwd`
attribute="displayName"
attribute_view="distinguishedName"

. $PWD/config/.ldap.properties

ldap_options=""
ldap_res=""

function ldap {	
	echo Executando:
	echo ldapsearch $ldap_options -x -h$ldap_host -p$ldap_port -b "'$searchBase'" -D "'$userDN'" -w "'$userPass'" "'$searchFilter'" $attribute
#	if [ "$attribute_view" ]; then
#		ldapsearch $ldap_options  -x -h$ldap_host -p$ldap_port -b "$searchBase" -D "$userDN" -w "$userPass" "$searchFilter" $attribute | grep $attribute_view	
	
#	else
		ldap_res=`ldapsearch $ldap_options  -x -h$ldap_host -p$ldap_port -b "$searchBase" -D "$userDN" -w "$userPass" "$searchFilter" $attribute`
#	fi
}

while [ ! "$yn" == "y" ] 
do
	read -p "Servidor LDAP [$ldap_host]: " p
	if [ ! "$p" == "" ]; then
		ldap_host="$p"
	fi
        read -p "Porta [$ldap_port]: " p
        if [ ! "$p" == "" ]; then
                ldap_port="$p"
        fi
	echo "Verificando conexão com ldap://$ldap_host:$ldap_port"
	nc -zv $ldap_host $ldap_port
	if [ ! $? == 0 ]; then
		echo "Falha de conexão. Verificar se os dados do servidor e porta ou se há restrições no firewall."		
		continue
	else
		echo "Usuário com permissão de consulta na base LDAP:"
		read -p "[DN=$userDN]: " p
		if [ ! "$p" == "" ]; then
			userDN="$p"
		fi
		read -s -p "Senha [$userPass]: " p
		if [ ! "$p" == "" ]; then
			userPass="$p"			
		fi
		
		echo ""
		read -p "Digite o escopo da busca na base LDAP: [$searchBase]: " p
                if [ ! "$p" == "" ]; then
                        searchBase="$p"
                fi
		read -p "Testar validação de login: [$account_name]: " p
		if [ ! "$p" == "" ]; then
                        account_name="$p"
                fi
		read -p "Aplicar filtro de teste [$userSearchFilter]: " p
		if [ ! "$p" == "" ]; then
			userSearchFilter="$p"
                fi
		userSearchFilter="$(echo "$userSearchFilter" | sed "s/{0}/$account_name/")"
		searchFilter="$userSearchFilter"
		ldap_options="-LLL"
		attribute="dn"
		ldap		
		echo "$ldap_res"
		#echo "$ldap_res" | awk -F ':' {'print $1'}
		read -p "Testar pesquisa de grupos: [$groupSearchFilter]. Tecle ENTER para continuar "	p
		if [ ! "$p" == "" ]; then
                        groupSearchFilter="$p"
                fi
		ldap_options=""
		attribute="displayName"
		groupSearchFilter="$(echo "$groupSearchFilter" | sed "s/{0}/$account_name/")"
		searchFilter="$groupSearchFilter"
		ldap

	        read -p "Deseja aplicar configuração? (y/n): "  yn
	        if [ "$yn" == "y" ]; then
	                echo "Aplicando configuração"
	        fi
	
	fi
done

