#*****************************
#********** Functions ********
#*****************************


printUsage() {
  cat <<EOF
Usage: testActivity -q QUEUE -z ZONE -Q QUALIFIERS [-v]

EXAMPLE:
	XNQ1	./testActivity_QueueUpdated.sh -q user -z z12059f.ningops.com -Q "psalas,psalas1" -v
	XNA	./testActivity_QueueUpdated.sh -q app -z z200410.ningops.com -Q "activityserver,OpenSocial-Qa1,opensocial-qa2" -v
	
DETAILS:
	-q QUEUE		The queue to read from. The valid queue types are the following:
				- app
				- user
				- friends-of

	-z ZONE			The zone url to request information from.

	-Q QUALIFIERS		coma-separated list of qualifiers. For users, a list of NingId's.
				For applications, a list of subdomains.

	-v			verbose output of request

NOTES: See http://jira.ninginc.com/browse/NING-9713 for more information

EOF
}


#*****************************
#************ Main ***********
#*****************************

path=`pwd`;
endPoint='/xn/rest/activity/1.0/queueUpdated';
options='';
verbose=0;
use_token=1;

# Check that there are at least 6 parameters
if (test $# -lt 6)
then
	printUsage;
	exit;
else
	while [ "$1" != '' ]
	do
		case $1
		in
		-q)
			queue=$2;
			shift 2;;
		-z)
			zone=$2;
			zone_ip=`host $zone | awk '{print $4}'`;
			shift 2;;
		-v)
			verbose=1;
			shift 1;;
		-Q)
			qualifiers=$2;
			shift 2;;
		-options)
			options=$2;
			shift 2;;
		*)
			echo "[ERROR] Uknown Parameter: '$1'";
			printUsage;
			exit;;
		esac
	done
fi


endPoint="$endPoint?name=$queue&qualifiers=$qualifiers";


cat <<EOF
DEBUG INFO
==========
zone: '$zone'
zone_ip: '$zone_ip'
app_id: $app_id
requestToken: '$requestToken'
queue: '$queue'
qualifiers: '$qualifiers'
endPoint: '$endPoint'
verbose: $verbose

\$ curl -vL -X GET "http://$zone_ip:8080$endPoint"

========================

EOF

if [ $verbose -eq 1 ]
then
	# Without Token
	curl -vL -X GET "http://$zone_ip:8080$endPoint" -D $path/../tmp/header | tee $path/../tmp/temp;
else
	# Without Token
	curl -vL -X GET "http://$zone_ip:8080$endPoint" -D $path/../tmp/header > $path/../tmp/temp;
fi

# Tests
test1=`cat $path/../tmp/header | grep -c "200 OK"`;
response_count=`cat $path/../tmp/temp | grep -c "<entry"`;

echo '';
echo '';
if (test $test1 -ge 1)
then
  echo "*** PASS ***";
else
  echo "*** FAIL - Expected 100 Continue ***";
  cat $path/../tmp/header;
fi
