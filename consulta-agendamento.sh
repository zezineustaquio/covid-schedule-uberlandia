#!/bin/bash
CPF=$1
DT_NASCIMENTO=$2

F_RESET="\e[0m"
F_RED="\e[31m"
F_GREEN="\e[32m"
F_BOLD="\e[1m"
F_RESET_BOLD="\e[21m"
F_BLINK="\e[5m"
F_REVERSE="\e[7m"

F_BG_RED="\e[41m"
F_BG_GREEN="\e[42m"
F_BG_BLUE="\e[44m"

echo -e $F_BLINK"Consultando vacinação para $CPF"$F_RESET

request_cripto () {
	echo `curl -XPOST -s 'https://agendamentosaude.uberlandia.mg.gov.br/ajax.php' \
		--header 'Accept:text/plain' \
		--header 'Content-Type:application/x-www-form-urlencoded' \
		--data-urlencode "param=$1" \
		--data-urlencode 'acao=CRPARAMSYS'` | base64 | tr --delete '\n'
}

request_cadastro () {
	local ACAO='$2y$10$YOmgjIaHt8iw3xSMAZcrr.iDykFF61LmIFVitE/ZMWCIF40vzS.K.'
	echo `curl -XGET -s "https://agendamentosaude.uberlandia.mg.gov.br/rest.php?acao=$ACAO&cpf=$1&dnasc=$2"`
}

request_dose () {
	local ACAO='$2y$10$8TMxYXS5mOeOe0KSze9b2ueYptljwPiwDLaaV1spQCCo7FbnaZ9.6'
	echo `curl -XGET -s "https://agendamentosaude.uberlandia.mg.gov.br/rest.php?acao=$ACAO&codigo=$1&dose=$2"`
}

print_dose () {
	local JSON="$1"
	if [ "$JSON" == "[]" ] ; then
		echo -e $F_BG_RED$F_BOLD"Não Disponível"$F_RESET
	else
		for row in $(echo "${JSON}" | jq -r '.[] | @base64'); do
			_jq() {
				echo ${row} | base64 --decode | jq -r ${1}
			}
			echo "Vacina agendada para: $(_jq '.dtAgendamento')"
			echo "Local de vacinação: $(_jq '.nmLocalVacinacao')"

			local SITUACAO=$(_jq '.tpSituacao')
			if [ "$SITUACAO" == "X" ] ; then
				SITUACAO=$F_RED"Não Vacinado"$F_RESET
			fi
			if [ "$SITUACAO" == "V" ] ; then
				SITUACAO=$F_GREEN$F_BOLD"Vacinado"$F_RESET
			fi
			echo -e "Situação: $SITUACAO"

			echo -e $F_REVERSE
			echo -e "---------------------------"
			echo -e $F_RESET
		done
	fi
}

CRIPT_CPF=`request_cripto $CPF`
CRIPT_DT_NASCIMENTO=`request_cripto $DT_NASCIMENTO`

DADOS=`request_cadastro $CRIPT_CPF $CRIPT_DT_NASCIMENTO`

if [ "$DADOS" == "" ] ; then
	echo -e "$F_BG_RED$F_BOLD CPF ou Data de Nascimento inválidos! $F_RESET"
	exit 1
fi
echo -e $F_BG_BLUE
echo -e "#############################"
echo -e "####  Dados de Cadastro  ####"
echo -e "#############################$F_RESET"
echo -e $DADOS | jq -C .

ID_SAUDE=`echo $DADOS | jq '.[0].oidAgendamentoSaude'`
CRIPT_ID_SAUDE=`request_cripto $ID_SAUDE`

CRIPT_DOSE_1=`request_cripto "1"`
DOSE_1=`request_dose $CRIPT_ID_SAUDE $CRIPT_DOSE_1`
echo -e $F_BG_BLUE
echo -e "############################"
echo -e "######### $F_BOLD 1 Dose $F_RESET_BOLD #########"
echo -e "############################$F_RESET"
echo -e "$(print_dose "$DOSE_1")"

CRIPT_DOSE_2=`request_cripto "2"`
DOSE_2=`request_dose $CRIPT_ID_SAUDE $CRIPT_DOSE_2`
echo -e $F_BG_BLUE
echo -e "############################"
echo -e "######### $F_BOLD 2 Dose $F_RESET_BOLD #########"
echo -e "############################$F_RESET"
echo -e "$(print_dose "$DOSE_2")"

CRIPT_DOSE_3=`request_cripto "3"`
DOSE_3=`request_dose $CRIPT_ID_SAUDE $CRIPT_DOSE_3`
echo -e $F_BG_BLUE
echo -e "############################"
echo -e "######### $F_BOLD 3 Dose $F_RESET_BOLD #########"
echo -e "############################$F_RESET"
echo -e "$(print_dose "$DOSE_3")"