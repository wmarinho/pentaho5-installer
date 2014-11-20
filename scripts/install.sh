#!/bin/bash
printf "\033c"
echo "##########################################################"
echo "##########  INSTACAÇÃO PENTAHO BISERVER CE ###############"
echo "##########################################################"

pentaho_dir="/opt/pentaho"
loginfo=debug #none | debug
PWD=`pwd`
install_opt="biserver-ce"
#install_src_dir="$pentaho_dir/src"
install_src_dir="$PWD/src"
username="pentaho"
database="postgresql"

#set -e
#chmod +x $PWD/scripts/*.sh


# http://sourceforge.net/projects/pentaho/files/Business%20Intelligence%20Server/5.2/biserver-ce-5.2.0.0-209.zip/download
#biserver_tag="5.0.1-stable"

biserver_tag_path="5.2"
biserver_tag_file="5.2.0.0-209"

if [ "$1" ]; then
        biserver_tag="$1"
fi
echo $biserver_tag

biserver_install_url="http://ufpr.dl.sourceforge.net/project/pentaho/Business%20Intelligence%20Server/$biserver_tag_path/biserver-ce-$biserver_tag_file.zip"

trunk=`echo $biserver_tag | grep TRUNK | wc -l`
echo $trunk
if [ ! "$trunk" == "0" ]; then
        biserver_install_url="http://ci.pentaho.com/job/BISERVER-CE/lastSuccessfulBuild/artifact/assembly/dist/biserver-ce-${biserver_tag}.zip"
fi


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
		#install_src_dir="$install_dir/src"
		showinfo "Info" "Baixando aplicação biserver-ce em $install_src_dir" $loginfo
		if [ -d "$install_src_dir" ]; then			
			prompt "Diretório $install_src_dir já existente. Tem certeza que deseja continuar? (y/n): "
		else
			showinfo "Info" "Criando diretório $install_src_dir" $loginfo
			`mkdir -p $install_src_dir`
		fi		  
               if [ -f "$install_src_dir/biserver-ce-$biserver_tag.zip" ]; then
		 showinfo "Info" "Arquivo já existe"  $loginfo
	        else
               		showinfo "Info" "wget -nv $biserver_install_url -O $install_src_dir/biserver-ce-$biserver_tag.zip" $loginfo
               		read -p "Executar comando? (y/n): " yn
			if [ "$yn" == "" ] ||  [ "$yn" == "y" ] || [ "$yn" == "Y" ]; then		      
		       		`wget "$biserver_install_url" -O "$install_src_dir/biserver-ce-$biserver_tag.zip"`
 			fi
		fi
		showinfo "Info" "Descompactando pacote em $install_dir ..."  $loginfo
		
		/usr/bin/unzip "$install_src_dir/biserver-ce-$biserver_tag.zip" -d "$install_dir"
		cp -r config $install_dir
		#cp -r etl $install_dir
		#cp -r scripts $install_dir
		cp -r lib  $install_dir
		mkdir $install_dir/{etl,scripts}
		
		chown -R "$username":"$username" "$install_dir/"
		create_uninstall
                ./scripts/setup.sh $install_dir $username

		#echo "Iniciando pentaho: sudo service pentaho start"
                #chown -R "$username":"$username" $install_dir
                #service pentaho start
                #echo "Para verificar o log, utilize: "
                #echo "sudo tail -f $install_dir/biserver-ce/tomcat/logs/catalina.out"
                #echo "Pare o serviço utilizando: sudo service pentaho stop"
                #echo "Verificando log ..."
                #tail -f "$install_dir/biserver-ce/tomcat/logs/catalina.out"

		;;
    esac
}

function create_uninstall {
	uninstall_file="scripts/_uninstall.sh"
	echo "#!/bin/bash" > $uninstall_file
	echo "userdel -f -r $username" >> $uninstall_file
	echo "rm -rf $install_dir" >> $uninstall_file
	echo "rm /etc/init.d/pentaho" >> $uninstall_file

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
    echo "Para RedHat/CentOS, utilize: sudo yum install java-1.7.0-openjdk && sudo alternatives --config java"
   
   echo "Para Ubuntu, utilize:  sudo apt-get install openjdk-7-jre-headless"
    exit 0    
fi

if [[ "$_java" ]]; then
    version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
    showinfo "Info" "Versão $version" $loginfo
    if [[ "$version" < "1.7" ]]; then
        echo "Necessário upgrade para java versão 1.7"
	echo "Para RedHat/CentOS, utilize: sudo yum install java-1.7.0-openjdk && sudo alternatives --config java"
	echo "Para Ubuntu, utilize:  sudo apt-get install openjdk-7-jre-headless"
	exit 0

    fi

else
    echo Erro: Instalação cancelada. Necessário instalação do java
    echo "Para RedHat/CentOS, utilize: sudo yum install java-1.7.0-openjdk && sudo alternatives --config java"
    echo "Para Ubuntu, utilize:  sudo apt-get install openjdk-7-jre-headless"
    exit 0
fi

if ! type -p unzip; then
    echo Erro: Instalação cancelada. Necessário unzip
    echo "Para RedHat/CentOS, utilize: sudo yum install unzip"
    echo "Para Ubuntu, utilize:  sudo apt-get install unzip"
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


