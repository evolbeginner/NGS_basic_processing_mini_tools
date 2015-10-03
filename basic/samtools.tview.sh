#! /bin/bash

sam_file=$1
genome=$2

if grep "sam$" <<< $sam_file -q; then
	core_name=${sam_file%.sam}
fi

bam_file=$core_name.bam
sorted_bam_file_prefix=$bam_file.sorted

samtools view -bS $sam_file -o $bam_file

samtools sort $bam_file $sorted_bam_file_prefix

samtools index $sorted_bam_file_prefix.bam

[[   -z $genome ]] && tview_genome=''
[[ ! -z $genome ]] && tview_genome=$genome
samtools tview $sorted_bam_file_prefix.bam $genome

