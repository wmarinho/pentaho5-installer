#!/bin/bash
echo "##########################################################"
echo "##########  CONFIGURAÇÃO PENTAHO BISERVER CE #############"
echo "##########################################################"

install_dir=/opt/pentaho

jvm_memory="-Xms2048m -Xmx1024m"

if [ -n "$1" ]; then
	install_dir=$1
fi

if [ ! -d "$install_dir" ]; then
   echo "Diretório [$install_dir] não encontrado." 
   read -q "Entre com o diretório de instalação: " install_dir
   if [ ! "$install_dir" ] && [ ! -d "$install_dir" ]; then
	echo "Diretório [$install_dir] não encontrado. Cancelando configuração"
	exit 0
    fi
fi

start_config_path="$install_dir/config/start-pentaho.sh"
start_pentaho_path="$install_dir/biserver-ce/start-pentaho.sh"
start_pentaho_path_tmp="$install_dir/biserver-ce/start-pentaho.sh.tmp"

if [ -f "$start_pentaho_path_tmp" ]; then
	rm $start_pentaho_path_tmp
fi

cp "$start_pentaho_path" "${start_pentaho_path}.bkp"

function replace_config {

   echo "Parâmetros: $# => $1 $2 $3 $4"
   if [ $# -eq 4 ] && [ -f $3 ]; then
	sed "s/$1/$2/g" "$3" >  "$4"
	if [ $? -ne 0 ]; then
		echo "Erro: Configuração não aplicada"		 		
		exit 0;
	fi
   else
	echo "Erro: Parâmetros inválidos. Configuração não aplicada"
	exit 0;
   fi
}


#Define parâmetros da JVM
function setparam {

   MemTotal=`echo "$(cat /proc/meminfo | grep MemTotal | awk '{print $2}') / 1024" | bc`
   MemFree=`echo "$(cat /proc/meminfo | grep MemFree | awk '{print $2}') / 1024" | bc`

   echo "Configurar parâmetros de memória para JVM."
   echo "Total de memória: ${MemTotal} MB / Memória livre: ${MemFree} MB"
   read -p "Tecle ENTER para confirmar ou digite a configuração desejada [$jvm_memory]" memory
   if [ "$memory" ]; then
	jvm_memory=$memory
   fi
    
   
   linuxbitness=`getconf LONG_BIT`
   if [ ${linuxbitness} == "64" ]; then
        replace_config "\$Xms_64 \$Xmx_64" "$jvm_memory" "$start_config_path"  "$start_pentaho_path_tmp"
   else
        replace_config "\$Xms_32 \$Xmx_32" "$jvm_memory" "$start_config_path"  "$start_pentaho_path_tmp"
   fi

   read -p "Parâmetros adicionais em (CATALINA_OPTS):" cat_opts
   if [ "$cat_opts" ]; then
	replace_config "\$cat_opts" "$cat_opts" "$start_config_path" "$start_pentaho_path_tmp"
   fi

}


if [ -f "$start_pentaho_path" ] && [ -f  "$start_config_path" ]; then
	setparam
	if [ $? -ne 0 ]; then
		exit 0
	fi
	read -p "Deseja aplicar configuração? (y/n) " apply
	if [ "$apply" == "y" ] || [ "$apply" == "Y" ]; then
		mv "$start_pentaho_path_tmp" "$start_pentaho_path"
 		echo "Configuração aplicada"
	fi

else
	echo Arquivo $start_pentaho_path ou $start_config_path não encontrado
fi
