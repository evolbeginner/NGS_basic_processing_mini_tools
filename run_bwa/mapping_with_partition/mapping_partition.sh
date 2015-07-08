#! /bin/bash

# pre-required programmes:
# 	bwa.sh 	=>	bwash
#	partition_fastq.sh	=>	partition_fastq_sh

bwash="/mnt/bay2/sswang/tools_program/NGS_scripts/bwa.sh"
partition_fastq_sh="`dirname $0`/partition_fastq.sh"

###################################################################################
read_param(){
	local PARAM=$@
	getopt_cmd="getopt -o 'i:o:h' --long in:,input:,ref:,pair,partition:,bwash:,partition_fastq_sh:,quiet,help, -- ${PARAM[@]}"
	PARAM=$($getopt_cmd)
	eval set -- "$PARAM"
	while : ; do	
		case $1 in
			-i|--in|--input)	input[$input_k]=$2
						((input_k++));		shift 2	;;
			--ref)			ref=$2;			shift 2	;;
			--partition)		partition=$2;		shift 2	;;
			--bwash)		bwash=$2;		shift 2 ;;
			--partition_fastq_sh)	partition_fastq_sh=$2;	shift 2 ;;
			--pair)			pair_param='--pair';	shift	;;
			--quiet)		exec 1>/dev/null;	shift   ;;
			-h|--help)		show_help;		shift	;;
			--)			break;			shift	;;
			*)			show_help;		shift	;;
		esac
	done

	for i in bwash partition_fastq_sh; do
		eval j=\$$i
		if [ ! -x $j -o ! -f $j ]; then echo "$i $j does not exist!"; exit 1; fi
	done
}

partition_fastq(){
	local input=$@
	for i in ${input[@]}; do
		$partition_fastq_sh -i $i --partition $partition
		[ $? -ne 0 ] && echo -e "\E[0;36;10mpartiton_fastq.sh\E[0;0;0m error" && exit 1
	done
}

run_bwa(){
	combine_sam(){
		local final_sam
		output_tmp=$1; eval output=\$$output_tmp
		final_sam=$2
		echo $final_sam
		echo ${output[@]}
		local header=`samtools view -SH ${output[1]}`
		echo $header
		for i in ${output[@]}; do
			samtools view -S $i | sponge $i
		done
		cat <<< "$header" | cat - ${output[@]} > $final_sam
	}

	if [ "$pair_param" ]; then
		local header
		for i in `seq $partition`; do
			local in1=${input[0]}.$i
			local in2=${input[1]}.$i
			output[$i]=${in1}_${in2}.sam
			echo "bwa ${input[$i]}"
			($bwash "--in $in1" "--in $in2" "--ref $ref" $pair_param)&
		done
		wait
		param_output='output'
		combine_sam $param_output final.sam
	else
		for j in ${input[@]}; do
			for i in `seq $partition`; do
				local in1=$j.$i
				output[$i]=${in1}.sam
				echo "bwa $j"
				($bwash "--in $in1" "--ref $ref") &
			done
			wait
			param_output='output'
			combine_sam $param_output final.$j.sam
		done
	fi
}

show_help(){
	echo "`basename $0` <--in input> <--ref ref> <--partiton partition> [--bwash=] [--partition_fastq_sh=] [--quiet] [--pair] [-h|--help]"
	echo
}

###################################################################################
read_param $@

partition_fastq ${input[@]}

run_bwa

