#!/bin/bash
echo "##########################################################"
echo "##########  CONFIGURAÇÃO PENTAHO BISERVER CE #############"
echo "##########################################################"

install_dir=/opt/pentaho
username=pentaho

jvm_memory="-Xmx2048m -Xms1024m"

if [ -n "$1" ]; then
	install_dir=$1
fi
if [ -n "$2" ]; then
        username=$2
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
stop_pentaho_path="$install_dir/biserver-ce/stop-pentaho.sh"

if [ -f "$start_pentaho_path_tmp" ]; then
	rm $start_pentaho_path_tmp
fi

cp "$start_pentaho_path" "${start_pentaho_path}.bkp"

function replace_config {

   #echo "Parâmetros: $# => $1 $2 $3"
   if [ $# -eq 3 ] && [ -f $3 ]; then
	new=$(echo "$2" | sed 's/\//\\\//g')
	sed -i "s/$1/$new/g" "$3" 
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
   echo "------------------------------------------"
   echo "Configurar parâmetros de memória para JVM."
   echo "------------------------------------------"
   echo "Total de memória: ${MemTotal} MB / Memória livre: ${MemFree} MB"

     if [ "${MemTotal}" -le 768 ]; then 	jvm_memory="-Xmx512m -Xms256m" 
   elif [ "${MemTotal}" -le 1024 ]; then	jvm_memory="-Xmx768m -Xms256m"
   elif [ "${MemTotal}" -le 1576 ]; then	jvm_memory="-Xmx1024m -Xms512m"
   elif [ "${MemTotal}" -le 2048 ]; then	jvm_memory="-Xmx1576m -Xms768m"
   elif [ "${MemTotal}" -le 3072 ]; then	jvm_memory="-Xmx2048m -Xms1024m"
   elif [ "${MemTotal}" -le 4096 ]; then	jvm_memory="-Xmx3072m -Xms1576m"
   elif [ "${MemTotal}" -le 6144 ]; then	jvm_memory="-Xmx4096m -Xms2048m"
   elif [ "${MemTotal}" -le 8192 ]; then	jvm_memory="-Xmx6144m -Xms3072m" 
   elif [ "${MemTotal}" -le 12288 ]; then 	jvm_memory="-Xmx8192m -Xms4096m"
   elif [ "${MemTotal}" -le 16384 ]; then 	jvm_memory="-Xmx12288m -Xms6144m"
   else 					jvm_memory="-Xmx16384m -Xms8192m"
   fi   

   read -p "Tecle ENTER para confirmar ou digite a configuração desejada [$jvm_memory]: " memory
   if [ "$memory" ]; then
	jvm_memory=$memory
   fi
    
   cp "$start_config_path"  "$start_pentaho_path_tmp"
   linuxbitness=`getconf LONG_BIT`
   if [ ${linuxbitness} == "64" ]; then
        replace_config "\$Xms_64 \$Xmx_64" "$jvm_memory" "$start_pentaho_path_tmp"
   else
        replace_config "\$Xms_32 \$Xmx_32" "$jvm_memory" "$start_pentaho_path_tmp"
   fi

   read -p "Parâmetros opcionais (-Dfile.encoding=utf8 -Djava.awt.headless=true) :" cat_opts
   if [ "$cat_opts" ]; then
	replace_config "\$cat_opts" "$cat_opts" "$start_pentaho_path_tmp"
   fi

}

function initonboot {
	echo "----------------------------------------------------"
	echo "Preparando configuração de inicialização automática."
	echo "----------------------------------------------------"
	if [ -f "$install_dir/config/init_pentaho.tmp" ]; then
		rm "$install_dir/config/init_pentaho.tmp"
	fi
	if [ -d "/etc/init.d" ]; then
		cp "$install_dir/config/init_pentaho" "$install_dir/config/init_pentaho.tmp"
		if [ -e "/etc/init.d/pentaho" ]; then
			read -p "Arquivo de inicialização já existente. Deseja sobrescrever? (y/n): " yn
				if [ "$yn" == "" ] ||   [ "$yn" == "y" ] || [ "$yn" == "Y" ]; then
					replace_config "\$username" "$username" "$install_dir/config/init_pentaho.tmp"
					replace_config "\$start_pentaho_script" "$start_pentaho_path" "$install_dir/config/init_pentaho.tmp"
					replace_config "\$stop_pentaho_script" "$stop_pentaho_path" "$install_dir/config/init_pentaho.tmp"
					read -p "Deseja aplicar configuração em /etc/init.d/pentaho? (y/n) " apply
        				if [ "$apply" == "" ] || [ "$apply" == "y" ] || [ "$apply" == "Y" ]; then
	                			mv  "$install_dir/config/init_pentaho.tmp" "/etc/init.d/pentaho"
						chmod +x "/etc/init.d/pentaho"
						#chkconfig pentaho on
						
                				echo "Configuração de inicialização aplicada"
						#echo "Iniciando pentaho: sudo service pentaho start"
						#chown -R "$username":"$username" $install_dir
			                        #service pentaho start
						#echo "Para verificar o log, utilize: "
						#echo "sudo tail -f $install_dir/biserver-ce/tomcat/logs/catalina.out"
						#echo "Pare o serviço utilizando: sudo service pentaho stop"
                        		        #echo "Verificando log ..."
                               			#tail -f "$install_dir/biserver-ce/tomcat/logs/catalina.out"	
										
        				fi
				fi
			
		else
                        replace_config "\$username" "$username" "$install_dir/config/init_pentaho.tmp"
			replace_config "\$start_pentaho_script" "$start_pentaho_path" "$install_dir/config/init_pentaho.tmp"
			replace_config "\$stop_pentaho_script" "$stop_pentaho_path" "$install_dir/config/init_pentaho.tmp"
                        read -p "Deseja aplicar configuração em /etc/init.d/pentaho? (y/n) " apply
                        if [ "$apply" == "" ] || [ "$apply" == "y" ] || [ "$apply" == "Y" ]; then
                               mv  "$install_dir/config/init_pentaho.tmp" "/etc/init.d/pentaho"
			       chmod +x "/etc/init.d/pentaho"
			       #chkconfig pentaho on
				 echo "Configuração de inicialização aplicada"
                                 #echo "Iniciando pentaho: sudo service pentaho start"
                                 #chown -R "$username":"$username" $install_dir
                                 #service pentaho start
                                 #echo "Para verificar o log, utilize: "
                                 #echo "sudo tail -f $install_dir/biserver-ce/tomcat/logs/catalina.out"
                                 #echo "Pare o serviço utilizando: sudo service pentaho stop"
                                 #echo "Verificando log ..."
                                 #tail -f "$install_dir/biserver-ce/tomcat/logs/catalina.out"
 
                        fi
			
		fi
		

	else
		echo "Diretório /etc/init.d não encontrado"
	fi
}


if [ -f "$start_pentaho_path" ] && [ -f  "$start_config_path" ]; then
	setparam
	if [ $? -ne 0 ]; then
		exit 0
	fi
	read -p "Deseja aplicar configuração de memória? (y/n) " apply
	if [ "$apply" == "" ] || [ "$apply" == "y" ] || [ "$apply" == "Y" ]; then
		mv "$start_pentaho_path_tmp" "$start_pentaho_path"
 		echo "Configuração aplicada"
	fi
	
	initonboot

else
	echo Arquivo $start_pentaho_path ou $start_config_path não encontrado
fi
