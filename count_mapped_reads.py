#! /bin/env python

import HTSeq
import sys

###########################################################################################
def aligned_counts(ifile1):
    '''count how many alignments are aligned back to genome, ifile1 is a sorted bam file'''
    import HTSeq
    sortedbamfile= HTSeq.BAM_Reader(ifile1)
    aligned_counts=0
    unaligned_counts=0
    for almnt in sortedbamfile:
        if almnt.aligned:
            aligned_counts+= 1
        else:
            unaligned_counts+=1
    print "number of aligned tags of %s is %d " % (ifile1, aligned_counts)
    print "number of unaligned tags of %s is %d "% (ifile1, unaligned_counts)
    return aligned_counts

###########################################################################################
aligned_counts(sys.argv[1])

