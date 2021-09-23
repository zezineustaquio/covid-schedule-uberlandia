#!/bin/bash
CPF=$1
DT_NASCIMENTO=$2

echo "Consultando vacinação para $CPF"

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
	for row in $(echo "${JSON}" | jq -r '.[] | @base64'); do
		_jq() {
			echo ${row} | base64 --decode | jq -r ${1}
		}
		echo "Vacina agendada para: $(_jq '.dtAgendamento')"
		echo "Local de vacinação: $(_jq '.nmLocalVacinacao')"
		echo "##################################"
	done
}

CRIPT_CPF=`request_cripto $CPF`
CRIPT_DT_NASCIMENTO=`request_cripto $DT_NASCIMENTO`

DADOS=`request_cadastro $CRIPT_CPF $CRIPT_DT_NASCIMENTO`

if [ "$DADOS" == "" ] ; then
	echo "CPF ou Data de Nascimento inválidos!"
	exit 1
fi
echo "#############################"
echo "####  Dados de Cadastro  ####"
echo "#############################"
echo $DADOS | jq -C .

ID_SAUDE=`echo $DADOS | jq '.[0].oidAgendamentoSaude'`
CRIPT_ID_SAUDE=`request_cripto $ID_SAUDE`

CRIPT_DOSE_1=`request_cripto "1"`
DOSE_1=`request_dose $CRIPT_ID_SAUDE $CRIPT_DOSE_1`
echo "############################"
echo "#########  1 Dose  #########"
echo "############################"
echo "$(print_dose "$DOSE_1")"

CRIPT_DOSE_2=`request_cripto "2"`
DOSE_2=`request_dose $CRIPT_ID_SAUDE $CRIPT_DOSE_2`
echo "############################"
echo "#########  2 Dose  #########"
echo "############################"
echo "$(print_dose "$DOSE_2")"

CRIPT_DOSE_3=`request_cripto "3"`
DOSE_3=`request_dose $CRIPT_ID_SAUDE $CRIPT_DOSE_3`
echo "############################"
echo "#########  3 Dose  #########"
echo "############################"
echo "$(print_dose "$DOSE_3")"