#!/bin/bash

echo "##########################################################"
echo "##########  CONFIGURAÇÃO DE BANCO DE DADOS ###############"
echo "##########################################################"

PWD=`pwd`

database="postgresql"
datetime=`date +"%Y%m%d-%H%M"`
install_dir="/opt/pentaho"
db_user="postgres"
db_host="localhost"
db_port="5432"
#db_param="-U $db_user -h $db_host"
db_param="-U $db_user"
bkp_tag=""

if [ "$1" ]; then
        install_dir="$1"
fi
biserver_dir="$install_dir/biserver-ce"

read -p "Tecle ENTER para confirmar ou selecione o banco desejado [$database]:  " db
if [ "$db" ]; then
	database=$db
fi



if [ "$database" == "postgresql" ]; then
	echo "Iniciando configuração do $database"
	
else
	echo "Opção inválida. Somente postgresql disponível"
	exit 0;
fi

db_bkp_dir="/tmp/$database"
pentaho_bkp_dir="/tmp/bkp/pentaho-biserver"

function backup_db {

	echo "Fazendo backup do banco: $database"
	read -p "Incluir tag, exemplo: v0.1 (opcional): " tag
	if [ ! -d "$db_bkp_dir" ]; then
		su - $db_user -c "mkdir -p $db_bkp_dir"
	fi
        if [ ! -d "$pentaho_bkp_dir" ]; then
                mkdir -p $pentaho_bkp_dir
        fi
	
	#su - $db_user -c "pg_dumpall $db_param > $db_bkp_dir/pq_dump_pentaho_${datetime}.sql"
	#su - $db_user -c "pg_dumpall -c $db_param | gzip > $db_bkp_dir/pentaho-bkp-${tag}-${database}-${datetime}.sql.gz"
	pg_dumpall -c $db_param | gzip > $db_bkp_dir/pentaho-bkp-${tag}-${database}-${datetime}.sql.gz
}

function restore_db {
	echo "Restaurando banco: $database ..."
	ls "$db_bkp_dir" | grep "pentaho-bkp-"
	last_file=`ls -lrt "$db_bkp_dir" | awk '/pentaho-bkp-/ { f=$NF };END{ print f }'`

	read -p "Tecle ENTER para confirmar ou selecione o arquivo desejado [$last_file]: " backup_file
	if [ ! "$backup_file" ]; then
		backup_file=$last_file
	fi
	if [ -f "$db_bkp_dir/$backup_file" ];then
		echo "Restaurando $db_bkp_dir/$backup_file ..."
		#su - $db_user -c "gzip -cd $db_bkp_dir/$backup_file | psql -q $db_param"
		gzip -cd $db_bkp_dir/$backup_file | psql -q $db_param 
	fi
}

function backup_pentaho {
	read -p "Fazer backup do diretório de instalação do Pentaho? (y/n): " yn
	if [ "$yn" == "" ] || [ "$yn" == "y" ] || [ "$yn" == "Y" ]; then
		echo Salvando estado atual do Pentaho em $pentaho_bkp_dir ...
		echo "Pode levar alguns minutos ..."
		tar -czf "$pentaho_bkp_dir/pentaho-bkp-${tag}-biserver-ce-${datetime}.tgz" -C $install_dir "biserver-ce/"
	fi
}

function restore_pentaho {
        echo "Restaurando pentaho em $install_dir ..."
        ls "$pentaho_bkp_dir" | grep "pentaho-bkp-"
        last_file=`ls -lrt "$pentaho_bkp_dir" | awk '/pentaho-bkp-/ { f=$NF };END{ print f }'`

        read -p "Tecle ENTER para confirmar ou selecione o arquivo desejado [$last_file]: " backup_file
        if [ ! "$backup_file" ]; then
                backup_file=$last_file
        fi
        if [ -f "$pentaho_bkp_dir/$backup_file" ];then
                echo "Restaurando $pentaho_bkp_dir/$backup_file em $install_dir ..."
		echo "Pode levar alguns minutos ..."
		tar -xzf "$pentaho_bkp_dir/$backup_file" -C $install_dir
        fi
}

genpasswd() {
        local randompassLength
        if [ $1 ]; then
                randompassLength=$1
        else
                randompassLength=8
        fi

        rand_psw=</dev/urandom tr -dc A-Za-z0-9 | head -c $randompassLength
        echo $rand_pass
}


biserver_dir_tmp="/tmp/biserver-ce-tmp"
db_config_dir="$PWD/config/${database}/biserver-ce"


##INICIO CONFIGURAÇÃO 
read -p "Informe Hostname ou IP do servidor $database [$db_host]: " host
if [ "$host" ]; then
	db_host="$host"
fi

read -p "Informe a porta do servidor $database [$db_port]: " port
if [ "$port" ]; then
        db_port="$port"
fi

echo "Verificando conexão com $database. Executando: nc -zv $db_host $db_port"
nc -zv $db_host $db_port
if [ "$?" -ne "0" ]; then
        echo "Erro: Instalação cancelada. Falha na conexão com $database $db_host:$db_port ..."
        echo "Favor verificar dados de conexão."
        echo "Para instalação local utilizar: "
        echo "RedHat/Centos: sudo yum install postgresql postgresql-server"
        echo "Ubuntu:  sudo apt-get install postgresql postgresql-contrib"

        exit 0
fi

read -p "Informe nome usuário com permissão (DROP, CREATE, GRANT) no banco $database [$db_user]: " user
if [ "$user" ]; then
        db_user="$user"
fi

read -s -p "Informe a senha do usuário $db_user : " pass
if [ "$pass" ]; then
        db_pass="$pass"
fi
echo ""

pgpass="$db_host:$db_port:postgres:$db_user:$db_pass"
echo $pgpass > ~/.pgpass
chmod 0600 ~/.pgpass

#cat ~/.pgpass

echo "Gerando senhas para usuários no $database ..."
psw_hibuser=`genpasswd`
echo "hibuser=$psw_hibuser"
psw_jcr_user=`genpasswd`
echo "jcr_user=$psw_jcr_user"
psw_pentaho_user=`genpasswd`
echo "pentaho_user=$psw_pentaho_user"

read -p "Aplicar configurações? (y/n): " yn
if [ "$yn" == "" ] || [ "$yn" == "y" ] || [ "$yn" == "Y" ]; then
	#backup_db
	#backup_pentaho
	cp -r $db_config_dir $biserver_dir_tmp
	
	$PWD/scripts/replace.sh "localhost:5432" "$db_host:$db_port" -path "$biserver_dir_tmp/" -infile
	$PWD/scripts/replace.sh "@@hibuser@@" "$psw_hibuser" -path "$biserver_dir_tmp/" -infile
        $PWD/scripts/replace.sh "@@jcr_user@@" "$psw_jcr_user" -path "$biserver_dir_tmp/" -infile
        $PWD/scripts/replace.sh "@@pentaho_user@@" "$psw_pentaho_user" -path "$biserver_dir_tmp/" -infile
	$PWD/scripts/replace.sh "awsbiuser" "$db_user" -path "$biserver_dir_tmp/" -infile

	echo "$biserver_dir/tomcat/conf/Catalina"
        rm -rf "$biserver_dir/tomcat/conf/Catalina"
	rm -rf "$biserver_dir/tomcat/temp/*.*"
	rm -rf "$biserver_dir/tomcat/work/*.*"
	rm -rf "$biserver_dir/tomcat/logs/*.*"

	cp -r $biserver_dir_tmp/* $biserver_dir/

	sql_script_dir="$biserver_dir_tmp/data/$database"
	db_param="-U $db_user -h $db_host -p $db_port -d postgres"
	if [ -f "$sql_script_dir/create_quartz_postgresql.sql" ]; then
		#su - $db_user -c "psql $db_param < $sql_script_dir/create_quartz_postgresql.sql"
		psql $db_param < $sql_script_dir/create_quartz_postgresql.sql
	fi
	
	if [ -f "$sql_script_dir/create_repository_postgresql.sql" ]; then
		#su - $db_user -c "psql $db_param < $sql_script_dir/create_repository_postgresql.sql"
		psql $db_param < $sql_script_dir/create_repository_postgresql.sql
	fi
	
	if [ -f "$sql_script_dir/create_jcr_postgresql.sql" ]; then
	       #su - $db_user -c "psql $db_param < $sql_script_dir/create_jcr_postgresql.sql"
		psql $db_param < $sql_script_dir/create_jcr_postgresql.sql
	fi
	
	#read -p "Deseja restaurar backup do ${database}? (y/n): " yn
	#if [ "$yn" == "y" ] || [ "$yn" == "Y" ]; then
	#		restore_db
	#fi
	#read -p "Deseja restaurar diretório de instalação do Pentaho? (y/n): " yn
	#if [ "$yn" == "y" ] || [ "$yn" == "Y" ]; then
	#        restore_pentaho
	#fi
	
	rm -rf $biserver_dir_tmp
fi			
