#!/bin/bash
#### Pre-reqs : curl and jq are installed
#### Parameters ... you may want to urlencode special characters
#### _cxlastscanmaxage in days
_cxuser="jb%40cx.com"
_cxpass="P%40ssw0rd"
_cxserver="http://jbcxvm"
#_cxteam="\\CxServer"
_cxlastscanmaxage=90
_output=stats.csv

#### Building output file header
echo "Project name,LOC,Scan date,Scan origin" > $_output

#### Let's first get an authentication token
_cxtoken=$(curl -s -X POST \
${_cxserver}/cxrestapi/auth/identity/connect/token \
-H 'Accept: application/json;v=1.0' \
-H 'Content-Type: application/x-www-form-urlencoded' \
-d "username=${_cxuser}&password=${_cxpass}&grant_type=password&scope=sast_rest_api&client_id=resource_owner_client&client_secret=014DF517-39D1-4453-B7B3-9930C563627C" \
| jq -r '.access_token')

#echo auth_token $_cxtoken

#### Then let's get the team id
#_cxteamid=$(curl -s -X GET \
#http://${_cxserver}/cxrestapi/auth/teams \
#-H 'Accept: application/json;v=1.0' \
#-H "Authorization: Bearer ${_cxtoken}" \
#| jq -r --arg _cxteam "$_cxteam" '.[] | select(.fullName == $_cxteam) | .id')
#echo teamid $_cxteamid

#### Loop on project id
for _cxprojectid in $(curl -s -X GET \
${_cxserver}/cxrestapi/projects \
-H 'Accept: application/json;v=1.0' \
-H "Authorization: Bearer ${_cxtoken}" \
| jq -r '.[].id')
do
	#echo projectid $_cxprojectid
	#### Get project last finished scan
	_cxprojscan=$(curl -s -X GET "${_cxserver}/cxrestapi/sast/scans?projectId=${_cxprojectid}&scanStatus=7&last=1" -H 'Accept: application/json;v=1.0' -H "Authorization: Bearer ${_cxtoken}")
	#### Get scan date
	_cxlastscandate=$(echo $_cxprojscan | jq -r ' .[].dateAndTime.startedOn ')
	#### Is there a last finished scan
	if [ $(echo $_cxprojscan | jq ' length ') -eq 0 ]
	then
		echo No finished scan found for project $_cxprojectid
	else
		#### Checking date validity
		_cxlastscandatestr=${_cxlastscandate:0:10}
		if [ $(date -d $_cxlastscandatestr +"%s") -lt $(expr $(date "+%s") - $(expr 86400 \* $_cxlastscanmaxage) ) ]
		then
			echo "Last finished scan too old for project $_cxprojectid : $_cxlastscandate (>$_cxlastscanmaxage days)"
		else
			#### Processing valid last scan
			echo Processing project $_cxprojectid
			_rprojname=$(echo $_cxprojscan | jq -r ' .[].project.name ')
			_rscanloc=$(echo $_cxprojscan | jq -r ' .[].scanState.linesOfCode')
			_rscandate=$_cxlastscandatestr
			_rscanorigin=$(echo $_cxprojscan | jq -r ' .[].origin')
			#### Output
			echo "${_rprojname},${_rscanloc},${_rscandate},${_rscanorigin}" >> $_output
		fi
	fi
done
