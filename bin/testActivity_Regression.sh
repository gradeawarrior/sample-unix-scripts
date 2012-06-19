#*****************************
#********** Functions ********
#*****************************


printUsage() {
  cat <<EOF
Usage: testActivity_Regression -o OPERATION [-c CONSOLE] [-q QUEUE -i QUEUE_INPUT] [-option OPTIONS] [-e ACTIVITY_ID] [-v] [-f FILE] [-n NUMBER_OF_ZONES] [-r RUNS] [-p POOL]

EXAMPLE:
	XNA:
		Run once on all zones in environment:
		./testActivity_Regression.sh -c gonsole.xna.ningops.net -q app -i activityserver -f xna/activity_create-activityserver.xml -o GET
		./testActivity_Regression.sh -c gonsole.xna.ningops.net -q app -i activityserver -f xna/activity_create-activityserver.xml -o POST

		Run on 1 zone 2 times:
		./testActivity_Regression.sh -c gonsole.xna.ningops.net -q app -i activityserver -f xna/activity_create-activityserver.xml -o GET -n 1 -r 2

	XNQ1:
		./testActivity_Regression.sh -c gonsole.xnq1.ningops.net -q app -i bazel311 -f xnq1/activity_create-bazel311.xml -o GET
		./testActivity_Regression.sh -c gonsole.xnq1.ningops.net -q app -i bazel311 -f xnq1/activity_create-bazel311.xml -o POST
		./testActivity_Regression.sh -c gonsole.xnq1.ningops.net -q app -i bazel-aclu1-network -f xnq1/activity_create-bazel-aclu1-network.xml -o GET
		./testActivity_Regression.sh -c gonsole.xnq1.ningops.net -q app -i bazel-aclu1-network -f xnq1/activity_create-bazel-aclu1-network.xml -o POST
		./testActivity_Regression.sh -c gonsole.xnq1.ningops.net -q app -i bazel-aclu2-network -f xnq1/activity_create-bazel-aclu2-network.xml -o GET
		./testActivity_Regression.sh -c gonsole.xnq1.ningops.net -q app -i bazel-aclu2-network -f xnq1/activity_create-bazel-aclu2-network.xml -o POST

	XNO:
		./testActivity_Regression.sh -c gonsole.xno.ningops.net -q app -i activityserver -f xno/activity_create_activityserver.xml -o GET
		./testActivity_Regression.sh -c gonsole.xno.ningops.net -q app -i activityserver -f xno/activity_create_activityserver.xml -o POST
DETAILS:
	-c CONSOLE		The galaxy console to perform operations

	-q QUEUE		The queue to read from. The valid queue types are the following:
				- app
				- user
				ss- friends-of

	-i QUEUE_INPUT		The input for the queue type. If for a user, then specify
				the valid NingId of the user. If for an app, specify a
				valid subdomain.

	-v			verbose output of request

	-options OPTIONS	Optional parameters for the request. (e.g. "?from=0&to=100")

	-e ACTIVITY_ID		This is used for the DELETE operation

	-f FILE			The file used for posting an event to the Activity Server

	-o OPERATION		The following operations can be performed:
					i) GET
					ii) POST
					iii) DELETE

	-n NUMBER_OF_ZONES	This is useful for controlling how many zones the operation will be performed on.
				For example, if there are 4 zones and you only want to run the request on 2, then
				only the first 2 zones will be called. The default is all zones in an environment
				will be called.

	-r RUNS			The number of times you want to retry the request on each zone. The default is 1.

	-p POOL			The pool to use. By default, all actc zones will be hit.
					i) general
					ii) beta

	-disable-token		Disables the use of request token

EOF
}


#*****************************
#************ Main ***********
#*****************************

path=`pwd`;
options='';
console='';
typeset -i num_cores=100;
typeset -i num_runs=1;

# Check that there are at least 8 parameters
if (test $# -lt 8)
then
	printUsage;
	exit;
else
	while [ "$1" != '' ]
	do
		case $1
		in
		-c)
			console=$2;
			shift 2;;
		-q)
			queue=$2;
			shift 2;;
		-i)
			input=$2;
			shift 2;;
		-v)
			verbosity=$1;
			shift 1;;
		-options)
			options=$2;
			shift 2;;
		-e)
			actc_id=$2;
			shift 2;;
		-operation)
			operation=$2;
			shift 2;;
		-f)
			file=$2;
			shift 2;;
		-o)
			operation=$2;
			shift 2;;
		-r)
			typeset -i num_runs=$2;
			shift 2;;
		-n)
			typeset -i num_cores=$2;
			shift 2;;
		-p)
			pool=$2;
			shift 2;;
		*)
			echo "[ERROR] Uknown Parameter: '$1'";
			printUsage;
			exit;;
		esac
	done
fi

# Setup console
if [ "$console" == "" ]
then
	if [ "$GALAXY_CONSOLE" == "" ]
	then
		echo "[ERROR] Galaxy console was not set";
		printUsage;
		exit;
	else
		console=$GALAXY_CONSOLE;
	fi
fi

# Setup pool to use
if [ "$pool" == "" ]
then
	pool="actc.*";
else
	pool="actc/$pool";
fi


# Debug Information
cat <<EOF
DEBUG INFO
==========
options: '$options'
queue: '$queue'
input: '$input'
actc_id: '$actc_id'
verbosity: '$verbosity'
file: '$file'
operation: '$operation'
console: '$console'
number_of_runs: $num_runs
number_of_cores: $num_cores
pool: '$pool'

List of ACTC zones on $console:
`galaxy -c $console -t $pool show`
========================

EOF

typeset -i core_runs=0;

if [ "$operation" == "GET" ]
then
	# Run GET requests tests against all zones in an environment
	for i in `galaxy -c $console -t $pool show | awk '{print $1}'`
	do
		# Check how many zones to iterate through
		if (test $core_runs -lt $num_cores)
		then
			# Check how many times to submit a GET request
			for (( j=1; j<=$num_runs; j++ ))
			do
				cat <<EOF

			##### Iterating through 'GET' operation on '$i' $j/$num_runs times #####

EOF
				./testActivity_GET.sh -z $i -q $queue -i $input $verbosity -options "$options";
			done
		else
			break;
		fi

		core_runs=$core_runs+1;			
	done
elif [ "$operation" == "DELETE" ]
then
	if [ "$actc_id" == "" ]
	then
		echo "[ERROR] Activity ID to delete is required";
		printUsage;
		exit;
	fi
	
	# Run GET requests tests against all zones in an environment
	for i in `galaxy -c $console -t $pool show | awk '{print $1}'`
	do
		# Check how many zones to iterate through
		if (test $core_runs -lt $num_cores)
		then
			# Check how many times to submit a GET request
			for (( j=1; j<=$num_runs; j++ ))
			do
				cat <<EOF

			##### Iterating through 'DELETE' operation on '$i' $j/$num_runs times #####

EOF
				./testActivity_DELETE.sh -z $i -e $actc_id;
			done
		else
			break;
		fi

		core_runs=$core_runs+1;			
	done
else
	# Run POST requests tests against all zones in an environment
	for i in `galaxy -c $console -t $pool show | awk '{print $7}'`
	do
		# Check how many zones to iterate through
		if (test $core_runs -lt $num_cores)
		then
			# Check how many times to submit a GET request
			for (( j=1; j<=$num_runs; j++ ))
			do
				cat <<EOF

			##### Iterating through 'POST' operation on '$i' $j/$num_runs times #####

EOF
				./testActivity_POST.sh -zone_ip $i -f $file $verbosity;
			done
		else
			break;
		fi

		core_runs=$core_runs+1;			
	done
fi
