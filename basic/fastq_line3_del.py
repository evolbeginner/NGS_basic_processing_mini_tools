#! /bin/env python

from Bio import SeqIO
import sys

fastq_parser = SeqIO.parse(sys.argv[1], "fastq") 
def my_filter(records):
    for rec in records:
        #print rec
        yield rec
        continue
        #if ...:
        #    yield rec

SeqIO.write(my_filter(fastq_parser), sys.argv[2], "fastq")

