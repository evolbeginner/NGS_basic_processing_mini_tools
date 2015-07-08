#! /bin/bash

################################################
bam="accepted_hits.bam"
cpu=1


################################################
function show_help(){
	echo "Param error! Exiting ......"
	exit
}


################################################
while [ $# -gt 0 ]; do
	case $1 in
		--gff)
			gff=$2
			shift
			;;
		--indir)
			indir=$2
			shift
			;;
		--cpu)
			cpu=$2
			shift
			;;
		--other_params)
			other_params=$2
			shift
			;;
		--outdir)
			outdir=$2
			shift
			;;
		*)
			show_help
	esac
	shift
done

for i in gff indir outdir; do
	eval p=\$$i
	[ -z $p ] && echo -e "The parameter $i is not given\n" && exit
done


################################################
for i in `find $indir -name "$bam"`; do
	date
	echo $i
	dir_basename=`basename $(dirname $i)`
	echo $dir_basename
	new_outdir=$outdir/$dir_basename
	cufflinks $i -G $gff -p $cpu $other_params -o $new_outdir
done



