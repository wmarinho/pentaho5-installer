#! /bin/bash

pentaho_dir=/opt/pentaho
loginfo=debug #none | debug
PWD=`pwd`
install_opt="$1"
install_src_dir="$pentaho_dir/src"
username=pentaho
#set -e



biserver_install_url="http://downloads.sourceforge.net/project/pentaho/Business%20Intelligence%20Server/5.0.1-stable/biserver-ce-5.0.1-stable.zip?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fpentaho%2Ffiles%2FBusiness%2520Intelligence%2520Server%2F5.0.1-stable%2F&ts=1394208071&use_mirror=ufpr"

printf "\033c"
echo "##########################################################"
echo "##########  INSTACAÇÃO PENTAHO BISERVER CE ###############"
echo "##########################################################"

if [ "$install_opt" == "" ]; then
   install_opt="biserver-ce"
fi


function usage {
  echo usage
}

function showinfo {
    if [ "$3" == "debug" ]; then
      echo "$1": "$2"
    fi
}

function prompt {
	read -p "$1" yn
        if [ "$yn" == "n" ] || [ "$yn" == "N" ]; then
            exit 0
        fi
}

function install {
    showinfo "Info" "Iniciando $1 em $install_dir ..."
    
    case "$1" in
	"biserver-ce") 
		showinfo "Info" "Iniciando instalação do biserver-ce" $loginfo
		install_src_dir="$install_dir/src"
		showinfo "Info" "Baixando aplicação biserver-ce em $install_src_dir" $loginfo
		if [ -d "$install_src_dir" ]; then			
			prompt "Diretório $install_src_dir já existente. Tem certeza que deseja continuar? (y/n): "
		else
			showinfo "Info" "Criando diretório $install_src_dir" $loginfo
			`mkdir -p $install_src_dir`
		fi		  
               if [ -f "$install_src_dir/biserver-ce-5.0.1-stable.zip" ]; then
		 showinfo "Info" "Arquivo já existe"  $loginfo
	        else
               		showinfo "Info" "wget $biserver_install_url -O $install_src_dir/biserver-ce-5.0.1-stable.zip" $loginfo
               		read -p "Executar comando? (y/n): " yn
			if ["$yn" == "" ] ||  [ "$yn" == "y" ] || [ "$yn" == "Y" ]; then		      
		       		`wget "$biserver_install_url" -O "$install_src_dir/biserver-ce-5.0.1-stable.zip"`
 			fi
		fi
		showinfo "Info" "Descompactando pacote em $install_dir ..."  $loginfo
		/usr/bin/unzip "$install_src_dir/biserver-ce-5.0.1-stable.zip" -d "$install_dir"
		cp -r config $install_dir
		cp -r etl $install_dir
		cp -r scripts $install_dir
		cp -r lib  $install_dir
		chown -R "$username":"$username" "$install_dir"
                sh ./scripts/setup.sh $install_dir $username
		;;
    esac
}



#while getopts c:hin: opt
#do
#   case "$opt" in
#      c) cell=$OPTARG;;
#      h) usage;;
#      i) info="yes";;
#      n) name=$OPTARG;;
#      \?) usage;;
#   esac
#done


showinfo "Info" "Verificando instalação do java" $loginfo

if [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
     showinfo "Info" "Executavel java encontrado em $JAVA_HOME/bin/java"
    _java="$JAVA_HOME/bin/java"
elif type -p java; then
    showinfo "Info" "Encontrado executável do java no PATH" $loginfo
    _java=java
else
    echo "Erro: Instalação cancelada. java não encontrado"
    exit 0    
fi

if [[ "$_java" ]]; then
    version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
    showinfo "Info" "Versão $version" $loginfo
    if [[ "$version" < "1.7" ]]; then
        echo Erro: Instalação cancelada. Necessário java versão 1.7
        exit 0

    fi

else
    echo Erro: Instalação cancelada. Necessário instalação do java
    exit 0
fi

if [[ "$JAVA_HOME" ]]; then
     showinfo "Info" "JAVA_HOME=$JAVA_HOME" $loginfo
else
    showinfo "Info" "JAVA_HOME não definido" $loginfo
fi

read -p "Digite o nome do usuário pentaho: " pentaho_user_name
if [ "$pentaho_user_name" ]; then
     username=$pentaho_user_name
fi

user_info=$(getent passwd $username)
#echo $user_info/
if [[ "$user_info" ]]; then
    user_dir=$(getent passwd $username | awk -F ':' '{print $6}')
    showinfo "Info" "Usuário $username encontrado no diretório $user_dir" $loginfo
    pentaho_dir="$user_dir"
else
    showinfo "Info" "Usuário $username não encontrado."
    read -p "Tecle ENTER para confirmar ou digite o nome do usuário [$username]: " pentaho_user_name
    if [ "$pentaho_user_name" ]; then
    	username= pentaho_user_name
    fi

    read -p "Tecle ENTER para confirmar ou digite o diretório do usuário $username [$pentaho_dir]: " pentaho_user_dir
    if [ "$pentaho_user_dir" ]; then
          pentaho_dir=$pentaho_user_dir
    fi
    pentaho_user_dir=$pentaho_dir
    showinfo prompt "Executar Comando: 'useradd -s /bin/bash -d $pentaho_user_dir $username'. Confirma? (y/n) "
    useradd -s /bin/bash -m -d "$pentaho_user_dir" $username
    chown -R $username:$username $pentaho_user_dir 
fi


    read -p "Tecle ENTER para confirmar ou digite o caminho de instalação: [$pentaho_dir]? " install_dir
    if [ "$install_dir" == "" ]; then
        install_dir=$pentaho_dir
        install $install_opt
    else
        if [ -d "$install_dir" ]; then
                prompt "Diretório $install_dir já existente. Tem certeza que deseja continuar a instalação? (y/n): "
                install $install_opt
        else
                showinfo "Info" "Criando diretório $install_dir" $loginfo
                install $install_opt

        fi
    fi


