#! /bin/bash

read_param(){
	local PARAM=$@
	getopt_cmd="getopt -o 'i:o:h' --long in:,input:,out:,output:,partition:,help, -- ${PARAM[@]}"
	PARAM=$($getopt_cmd)
	eval set -- "$PARAM"
	while true; do
		case $1 in
			-h|--help)		show_help;		shift	;;
			-i|--in|--input)	input="$2";		shift 2	;;
			-o|--out|--output)	output="$2";		shift 2	;;
			--partition)		partition="$2";		shift 2	;;
			--)			break;			shift	;;
			*)			show_help;		shift	;;
		esac
	done
}

check_param(){
	if [ -z $partition ] || [ ! 'grep -P /^\d$/ <<< $partiton' ]; then
		echo -e "param\E[0;36;10m partition \E[0;0;0merror!"
		show_help
		exit 0
	fi
}

partition(){
	local partition=$1
	if [ $partition -gt 4 ]; then
		partition=4
		echo "partition has been set to 4 since 4 is the maximun value!"
	fi
	total_line=`wc -l $input | sed 's/\(^[0-9]\+\).\+/\1/'`
	if [ `expr $total_line % 4` -ne 0 ]; then
		echo "The number of total line in the fastq file $in should be a multiple of 4!"
		exit
	fi
	
	num_of_read=`expr $total_line / $partition`
	echo "The number of reads is $num_of_read !"
	local num_of_line_per_Fen=`expr $total_line / $partition`
	echo $num_of_line_per_Fen
	num_of_read_per_Fen=`expr $num_of_line_per_Fen / 4`
	num_of_line_per_Fen2=$(($num_of_read_per_Fen*4))

	local start=1 end=$num_of_line_per_Fen2 k=1
	while [ $start -lt $total_line ]; do
		echo $start $end
		awk '{if(NR>='''$start'''&&NR<='''$end'''){print $0}}' $input > $input.$k && ((k++))
		[ ! $end -lt $total_line ] && break
		start=$(($start+$num_of_line_per_Fen2))
		end=$(($end+$num_of_line_per_Fen2))
		[ $(($end+$num_of_line_per_Fen2)) -gt $total_line ] && end=$total_line
	done
}

show_help(){
	echo "`basename $0` <--in input> <--out output> <--partition partition (max=4)> [-h|--help help]"
	exit 1;
}

###########################################################################
read_param $@;

check_param

partition $partition

