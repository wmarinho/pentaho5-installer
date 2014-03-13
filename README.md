#Procedimento de instalação do servidor Pentaho CE 5

O procedimento de instalação foi testado em uma instância EC2 Amazon, 64 bits, baseada no RedHat.

<pre>
cat /etc/system-release
Amazon Linux AMI release 2013.09

cat /proc/version
Linux version 3.4.76-65.111.amzn1.x86_64 (mockbuild@gobi-build-31004) (gcc version 4.6.3 20120306 (Red Hat 4.6.3-2) (GCC) ) #1 SMP
</pre>

##Preparação do ambiente

###Criação do usuário pentaho
Referência: [infocenter.pentaho.com](http://infocenter.pentaho.com/help/topic/install_manual/task_set_environment.html)
<pre>
sudo useradd -s /bin/bash -d /opt/pentaho pentaho
sudo passwd pentaho
sudo su - pentaho
</pre>

###Instalação do Java JRE ou JDK
Verificar instalação do java. [Baixar](http://www.oracle.com/technetwork/pt/java/javase/downloads/jre7-downloads-1880261.html) e instalar, se for o caso.
<pre>
java -version
java version "1.7.0_51"
</pre>
###Configurar variável de ambiente do Pentaho
Editar /etc/environment
<pre>
sudo vi /etc/environment
</pre>

e adicionar a linha abaixo de acordo com a instalação

<pre>
export PENTAHO_JAVA_HOME=/usr/lib/jvm/java
</pre>


###Instalação do Pentaho 5 CE

####1. Instalar a partir do site
* Acessar [community.pentaho.com](http://community.pentaho.com/) ou

* [Download direto do Pentaho CE versão 5.0.1](https://sourceforge.net/projects/pentaho/files/Business%20Intelligence%20Server/5.0.1-stable/) ou

* Baixar via wget
<pre>
sudo su - pentaho
wget 'http://downloads.sourceforge.net/project/pentaho/Business%20Intelligence%20Server/5.0.1-stable/biserver-ce-5.0.1-stable.zip?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fpentaho%2Ffiles%2FBusiness%2520Intelligence%2520Server%2F5.0.1-stable%2F&ts=1394208071&use_mirror=ufpr' -O biserver-ce-5.0.1-stable.zip
</pre>

* Descompactar pacote
<pre>
cd /opt/pentaho
unzip biserver-ce-5.0.1-stable.zip .
</pre>

####2. Instalar a partir do repositório Git
<pre>
cd /opt/pentaho
git clone https://github.com/wmarinho/pentaho5.git
cd pentaho5
unzip src/biserver-ce/biserver-ce-5.0.1-stable.zip .
</pre>

###Criar link simbólico
<pre>
ln -s /opt/pentaho/pentaho5/biserver-ce /opt/pentaho/biserver-ce
</pre>

###Ajustar parâmentros de inicialização do Tomcat 

* Alterar os parâmetros ```-Xms1024m -Xmx2048m -XX:MaxPermSize=256m``` de acordo com disponibilidade de memória do servidor.
* Adicionar ```-Dfile.encoding=utf-8```, para utilizar codificação de arquivos UTF-8
* Adicionar parâmetro ```-Djava.awt.headless=true``` para sistemas sem placa de vídeo. Caso não tenha X11, instalar pacote xvfb para realizar operações gráficas. Referência: [infocenter.pentaho.com](http://infocenter.pentaho.com/help/index.jsp?topic=%2Finstall_manual%2Ftask_set_environment.html)

<pre>
cd /opt/pentaho/biserver-ce
vi start-pentaho.sh
export CATALINA_OPTS="-Xms1024m -Xmx2048m -XX:MaxPermSize=256m -Dsun.rmi.dgc.client.gcInterval=3600000 -Dsun.rmi.dgc.server.gcInterval=3600000"
</pre>

### Criar script de inicialização automática no Boot do sistema

Referência: [infocenter.pentaho.com](http://infocenter.pentaho.com/help/index.jsp?topic=%2Fconfig_ba_server%2Ftask_starting_ba_server.html)

* Criar arquivo em /etc/init.d/
<pre>
sudo vi /etc/init.d/pentaho
</pre>

* Adicionar script ao arquivo:
<pre>
\#!/bin/sh
\# Provides: start-pentaho stop-pentaho
\# Required-Start: networking postgresql
\# Required-Stop: postgresql
\# Default-Start: 2 3 4 5
\# Default-Stop: 0 1 6
\# Description: Pentaho BA Server
case "$1" in
"start")
su - pentaho -c "/opt/pentaho/biserver-ce/start-pentaho.sh"
;;
"stop")
su - pentaho -c "/opt/pentaho/biserver-ce/stop-pentaho.sh"
;;
*)
echo "Usage: $0 { start | stop }"
;;
esac
exit 0
</pre>

* Tornar o arquivo executável:
<pre>
chmod +x /etc/init.d/pentaho
</pre>

* Configurar inicialização automática do servidor no boot
<pre>
sudo chkconfig pentaho on
</pre>

* Inicializar serviço
<pre>
service pentaho start
</pre>

* Parar serviço
<pre>
service pentaho stop
</pre>

* Para verificar se o serviço está rodando, execute o comando:
<pre>
ps -ef | grep java
</pre>

* Comandos para Verificar log de erros
<pre>
cd /opt/pentaho/biserver-ce/tomcat/logs/
tail -f catalina.out
cat catalina.out | less
tail -f pentaho.log
cat pentaho.log | less
</pre>


