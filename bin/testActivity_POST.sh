#*****************************
#********** Functions ********
#*****************************


printUsage() {
  cat <<EOF
Usage: testActivity -z ZONE -zone_ip IP [-f FILE] [-v]

EXAMPLES:
	./testActivity_POST.sh -z z12059f.ningops.com 
	./testActivity_POST.sh -zone_ip 10.18.40.126 
	./testActivity_POST.sh -z z200410.ningops.com -f ./xna/activity_create-centralizedsocialnetwork.xml
	./testActivity_POST.sh -z z200410.ningops.com -f xna/activity_create-activityserver.xml
	./testActivity_POST.sh -z z200410.ningops.com -f xna/activity_create-activityserver2.xml
	./testActivity_POST.sh -z z12059f.ningops.com -f ./xnq1/activity_create-bazel311.xml
	./testActivity_POST.sh -z z12066d.ningops.com -f ./xnb2/activity_create-testnetwork1.xml
	./testActivity_POST.sh -z z10111d.ningops.com -f xno/activity_create_activityserver.xml
	./testActivity_POST.sh -z z10111d.ningops.com -f xno/activity_create_activityserver2.xml
	
DETAILS:
	-z ZONE		The activity zone to post event to

	-zone_ip	This can be used instead of the -z option. This bypasses
			the 'host' command which retrieves the zone_ip. This is
			recommended for performance testing.

	-f FILE		Optional argument to specify the file to post to the activity zone. This is by default ./activity_create.xml

	-v		Optional verbose output of data
EOF
}


#*****************************
#************ Main ***********
#*****************************

path=`pwd`;
verbose=0;
use_token=1;

# Check that there are at least 2 parameters
if (test $# -lt 2)
then
	printUsage;
	exit;
else
	while [ "$1" != '' ]
	do
		case $1
		in
		-z)
			zone=$2;
			zone_ip=`host $zone | awk '{print $4}'`;
			shift 2;;
		-zone_ip)
			zone_ip=$2;
			shift 2;;
		-f)
			file=$2;
			shift 2;;
		-v)
			verbose=1;
			shift 1;;
		-disable-token)
			use_token=0;
			shift 1;;
		*)
			echo "[ERROR] Uknown Parameter: '$1'";
			printUsage;
			exit;;
		esac
	done
fi


if [ "$zone_ip" == "" ]
then
	printUsage;
	exit;
fi

# Check what file to post
if [ "$file" == "" ]
then
	file="$path/activity_create.xml";
fi

cat <<EOF
zone: '$zone'
zone_ip: '$zone_ip'
file: '$file'
verbose: $verbose

\$ curl -vL -X POST -T $file -H "Content-Type: application/atom+xml" "http://$zone_ip:8080/xn/rest/activity/1.0/event"

========================

EOF

if [ "$verbose" == "1" ]
then
	# Without Token
	curl -L -X POST -T $file -H "Content-Type: application/atom+xml" "http://$zone_ip:8080/xn/rest/activity/1.0/event" -D $path/../tmp/header | tee $path/../tmp/temp;
else
	# Without Token
	curl -L -X POST -T $file -H "Content-Type: application/atom+xml" "http://$zone_ip:8080/xn/rest/activity/1.0/event" -D $path/../tmp/header > $path/../tmp/temp;
fi

# Tests
test1=`cat $path/../tmp/header | grep -c "100 Continue"`;

echo '';
echo '';
if (test $test1 -ge 1)
then
  echo "*** PASS ***";
else
  echo "*** FAIL - Expected 202 Accepted ***";
fi
