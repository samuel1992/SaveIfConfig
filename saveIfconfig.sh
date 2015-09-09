#!/bin/bash
#
#script que le o comando IFCONFIG e filtra atraves de expressoes regulares as informacoes necessarias
#[...] para poder gerar um arquivo fixo (/etc/network/interfaces) 
#[...] script feito em SO Debian, foi adaptado para fedora com poucas mudanças.
#@by : Samuel Dantas (soh festa)
#date: 30/03/2015 

IFS_ORIGINAL='/etc/network/'
#IFS_ORIGINAL='/root/'
IFS_FILE='/opt/lampp/htdocs/logs/ifconfig-'$(date +"%d%m%Y-%H%M%S") #arquivo das interfaces
touch $IFS_FILE
GW_DEFAULT=`ip route show | egrep -e "^default*" | awk '{print $3}'` #coletando o ip do gateway padrao
IF_GW=`ip route show | egrep -e "^default*" | awk '{print $5}'` #coletando a ethX do gateway padrao

#
# funcao para mover o arquivo criado para o interfaces original
#
moveFile(){
        mv $1interfaces $2'.bkp'
        mv $2 $1interfaces 
}

#
# funcao para criar o inicio do arquivo onde contém o loopback
#
startFile(){
	#iniciando o conteudo do arquivo de redes com a interface de loopback
	echo "auto lo"                           > ${IFS_FILE}
	echo "iface lo inet loopback"           >> ${IFS_FILE}
}

#
# funcao principal que cria o arquivo final de redes
#
main(){
	startFile #funcao que monta o inicio do arquivo de redes		
	#comando base para obter os parametros do ifconfig filtrados em PLACA MACADRESS IP BROADCAST NETMASK
	#apos o comando ifconfig, filtro o ip de loopback, depois com uma simples expressao trago todas ethX (eth0, eth1 etc) e tambem as informacoes que procedem depois de 'inet end' (que sao ip, bcast, mask)
	#usando sed atraves de algumas expressoes regulares removo todas as palavras deixando apenas os numeros pertinentes
	#armazenando os resultados com o read em variaveis, utilizando loop while para pegar todas
	ifconfig | egrep -v "127.0.0.1" | egrep -e "eth.*" -e "inet\ end.*" | sed -e "N;s/Link.*HW\|\n\|inet\ end\.:\|Bcast\:\|Masc\:\|\    //g" | while read IF IF_MAC IF_IP IF_BCAST IF_MASK; do
	#montando o arquivo de configuracao de rede
	echo "auto ${IF}"			>> ${IFS_FILE}
	echo "iface ${IF} inet static"		>> ${IFS_FILE}
	echo "		address ${IF_IP}"	>> ${IFS_FILE}
	echo "		netmask ${IF_MASK}"	>> ${IFS_FILE}
	echo "		broadcast ${IF_BCAST}"	>> ${IFS_FILE}
	#fazendo verificacao para ver se essa placa eh quem se comunica com o gateway padrao
	if [ $(echo $IF_GW) == $IF ]; then
		echo "		gateway ${GW_DEFAULT}"	>> ${IFS_FILE}
	fi
	done #fim do while
	
	#exibindo mensagem para o usuario e gravando na variavel CHOICE
	echo "############### ARQUIVO ANTIGO ###############"
	cat $IFS_ORIGINAL\interfaces
	echo ""
	echo "############### ARQUIVO NOVO ###############"
	cat $IFS_FILE
	read -p "Você deseja salvar as alterações de rede permanentemente ? (s/n)" CHOICE
	#condicao para verificar a opcao digitada pelo usuario
	if [ $CHOICE == "s" ]; then
		#fazendo backup do arquivo original e copiando o antigo
		moveFile ${IFS_ORIGINAL} ${IFS_FILE}
	else 
		echo -e "As configurações não serão salvas!"
	fi
}

main

