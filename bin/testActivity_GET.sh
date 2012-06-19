#*****************************
#********** Functions ********
#*****************************


printUsage() {
  cat <<EOF
Usage: testActivity -q QUEUE -t QUEUE_INPUT -z ZONE [-option OPTIONS] [-v]

EXAMPLE:
	XNQ1	./testActivity_GET.sh -q app -i bazel311 -z z12059f.ningops.com 
	XNA	./testActivity_GET.sh -z z200410.ningops.com -q app -i centralizedsocialnetwork
	XNA	./testActivity_GET.sh -z z200410.ningops.com -q app -i activityserver
	XNA	./testActivity_GET.sh -z z200410.ningops.com -q app -i activityserver2
	XNB2	./testActivity_GET.sh -z z12066d.ningops.com -q app -i testnetwork1
	XNO	./testActivity_GET.sh -z z10111d.ningops.com -q app -i activityserver
	XNO	./testActivity_GET.sh -z z10111d.ningops.com -q app -i activityserver2
	
DETAILS:
	-q QUEUE		The queue to read from. The valid queue types are the following:
				- app
				- user
				- friends-of

	-i QUEUE_INPUT		The input for the queue type. If for a user, then specify
				the valid NingId of the user. If for an app, specify a
				valid subdomain.

	-z ZONE			The zone url to request information from.

	-v			verbose output of request

	-options OPTIONS	Optional parameters for the request. (e.g. "?from=0&to=100")
EOF
}


#*****************************
#************ Main ***********
#*****************************

path=`pwd`;
endPoint='/xn/rest/activity/1.0/queue';
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
		-i)
			input=$2;
			shift 2;;
		-z)
			zone=$2;
			zone_ip=`host $zone | awk '{print $4}'`;
			shift 2;;
		-v)
			verbose=1;
			shift 1;;
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


endPoint="$endPoint/$queue/$input$options";


cat <<EOF
DEBUG INFO
==========
zone: '$zone'
zone_ip: '$zone_ip'
options: '$options'
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
fi

cat <<EOF

OUTPUT STATS
============
# of entries: $response_count
EOF
