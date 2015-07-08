#! /bin/bash

bwa=bwa
#######################################################################################
#declare -A input	# a hash containing the input sequence files

#######################################################################################
read_param(){
	local PARAM
	PARAM=$@
	getopt_cmd="getopt -o 'i:o:h' --long mode:,in:,input:,out:,output:,ref:,cpu:,pair,quiet,help, -- $PARAM"
	PARAM=$($getopt_cmd)
	eval set -- "$PARAM"
	while true; do
		case $1 in
			-h|--help)		show_help;		shift	;;
			-i|--in|--input)	input[$input_k]="$2";
						((input_k++));		shift 2	;;
			-o|--out|--output)	output="$2";		shift 2	;;
			--ref)			reference="$2";		shift 2	;;
			--cpu)			cpu="$2";		shift 2	;;
			--pair)			paired_end=1;		shift	;;
			--quiet)		exec 1>/dev/null;	shift	;;
			--)			break;			shift	;;
			*)			show_help;		shift	;;
		esac
	done
}

check_param(){
	local tmp_var1 tmp_var2 mandatory_param
	mandatory_param=$@
	[ -z $cpu ] && cpu=1
	for i in ${mandatory_param[@]}; do
		eval tmp_var1=$i;	eval tmp_var2=\$$tmp_var1
		[ -z $tmp_var2 ] && show_help "mandatory param $tmp_var1 not defined"
		case $tmp_var1 in
			reference)
				[ ! -f $tmp_var2 ] && show_help "$tmp_var1 $tmp_var2 do not exist" ;;
			input)
				for j in ${input[@]}; do
					[ ! -f $j ] && show_help "$tmp_var1 $j do not exist"
				done
				;;
			paired_end)
				[ ${#input[@]} -lt 2 ] && show_help "The number of input files are less than 2\
					and cannot initiate paired_end alignment"
				input=(${input[0]} ${input[1]})
		esac
	done
}

process_param(){
	local file
	for i in ${!input[*]}; do
		file=${input[$i]}
		if [ -z ${output[$i]} ]; then
			if [ -z $paired_end ]; then
				output[$i]=`basename $file`'.sam'
			else
				output=`basename ${input[0]}`'_'`basename ${input[1]}`'.sam'
				return
			fi
		fi
	done
}

sai(){
	for i in ${!input[*]}; do
		sai[$i]=${input[$i]}.sai
	done
}

show_help(){
	echo -ne "\tError!\t"
	printf "\E[0;32;10m"; echo "$@"; printf "\E[0;0;0m"
	cat << EOF
	USAGE:	$0  <--in1 \$in1> <--in2 \$in2> <--ref \$ref>
	Options:
		--cpu			the number of cpu that would be used
		--pair			paired-end
		--quiet
		--help			show help
EOF
exit 1
}

#####################################################################################
mandatory_param=(input reference)

read_param $@;

check_param ${mandatory_param[@]}

process_param

sai

$bwa index -a bwtsw $reference

echo -e "aln\t......\t"
for i in ${!input[*]}; do
	$bwa aln -t $cpu $reference ${input[$i]} > ${sai[$i]}&
done
wait

echo -e "sam\t......\t"
if [ -z $paired_end ]; then
	for i in ${!input[@]}; do
		$bwa samse -f ${output[$i]} $reference ${sai[$i]} ${input[$i]}
	done
else
	$bwa sampe -f $output $reference ${sai[0]} ${sai[1]} ${input[0]} ${input[1]}
fi


