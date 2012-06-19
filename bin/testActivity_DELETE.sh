#*****************************
#********** Functions ********
#*****************************


printUsage() {
  cat <<EOF
Usage: testActivity -z ZONE -zone_ip IP -e EVENT_ID

EXAMPLES:
	XNA	./testActivity_DELETE.sh -z z200410.ningops.com -e 00000000000a4fa100000000000a1ce9eb66b97fcdde41a5
	XNQ1	./testActivity_DELETE.sh -z z12059f.ningops.com -e 00000000000a4fa100000000000a1ce9eb66b97fcdde41a5
	XNB2	./testActivity_DELETE.sh -z z12066d.ningops.com -e 00000000000a4fa100000000000a1ce9eb66b97fcdde41a5
	XNO	./testActivity_DELETE.sh -z z10111d.ningops.com -e 00000000000a4fa100000000000a1ce9eb66b97fcdde41a5
	
DETAILS:
	-z ZONE		The activity zone to post event to

	-zone_ip	This can be used instead of the -z option. This bypasses
			the 'host' command which retrieves the zone_ip. This is
			recommended for performance testing.

	-e EVENT_ID	Event id that is to be deleted
EOF
}


#*****************************
#************ Main ***********
#*****************************

path=`pwd`;
endPoint='/xn/rest/activity/1.0/event';
use_token=1;

# Check that there are at least 4 parameters
if (test $# -lt 4)
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
		-e)
			event_id=$2;
			shift 2;;
		*)
			echo "[ERROR] Uknown Parameter: '$1'";
			printUsage;
			exit;;
		esac
	done
fi


if (test "$zone_ip" -eq "")
then
	printUsage;
	exit;
fi

endPoint="$endPoint/$event_id";

cat <<EOF
zone: '$zone'
zone_ip: '$zone_ip'
requestToken: '$requestToken'
event_id: '$event_id'
endPoint: '$endPoint'

\$ curl -vL -X DELETE "http://$zone_ip:8080$endPoint"

========================

EOF

# Without Token
curl -vL -X DELETE "http://$zone_ip:8080$endPoint" -D $path/../tmp/header | tee $path/../tmp/temp;

# Tests
test1=`cat $path/../tmp/header | grep -c "204 No Content"`;

echo '';
echo '';
if (test $test1 -ge 1)
then
  echo "*** PASS ***";
else
  echo "*** FAIL - Expected 204 No Content ***";
fi
