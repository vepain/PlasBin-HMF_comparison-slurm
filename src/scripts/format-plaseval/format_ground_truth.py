#!/usr/bin/python

'''
USAGE: python format_ground_truth.py --gt PATH_TO_PFAM_GROUND_TRUTH_FILE \
							  		 --outdir PATH_TO_OUTPUT_FOLDER --outfile OUTPUT_FILENAME
'''

import argparse
import os
import pandas as pd

'''
Formatting functions:
- change the format of ground truth into PlasEval input format,
- input: path to ground truth file 
- output: None, changed format written directly to output file.
'''

def format_gt(GT_FILE, bins, LEN_THR):
    '''
    Ground truth:
    - CSV file with following format:
    - contig,plasmid_score,chrom_score,label,length,chr_coverage,pl_coverage,un_coverage,hybrid_mapsto
    '''
    GT_ALL_DF = pd.read_csv(GT_FILE, dtype={'hybrid_mapsto':'string'})
    GT_DF = GT_ALL_DF[GT_ALL_DF['length'] >= LEN_THR]
    #print(GT_DF)
    CHR_DF = GT_DF[GT_DF['label'] == 'chromosome']
    PLS_DF = GT_DF[GT_DF['label'] == 'plasmid']
    AMB_DF = GT_DF[GT_DF['label'] == 'ambiguous']

    print(CHR_DF['hybrid_mapsto'].unique())
    print(PLS_DF['hybrid_mapsto'].unique())
    CHR_MAPSTO = CHR_DF['hybrid_mapsto'].unique()
    CHR_IDS = set()
    for ctgs in CHR_MAPSTO:
        ctgs = ctgs.split(';')
        for ctg in ctgs:
            CHR_IDS.add(ctg)
    print(CHR_IDS)

    bins.write("plasmid\tcontig\tcontig_len\n")
    for index, row in PLS_DF.iterrows():
        ctg_id = row['contig']
        ctg_id = ctg_id.replace("_",":") #Contigs in renamed SKESA files have "_" replaced by ":"
        ctg_len = row['length']
        hyb_ctgs = row['hybrid_mapsto'].split(';')
        for hyb_id in hyb_ctgs:
            if hyb_id not in CHR_IDS:        
                bins.write('GT_'+str(hyb_id) + '\t' + str(ctg_id) + '\t' + str(ctg_len) + '\n')   

    for index, row in AMB_DF.iterrows():
        ctg_id = row['contig']
        ctg_id = ctg_id.replace("_",":") #Contigs in renamed SKESA files have "_" replaced by ":"
        ctg_len = row['length']
        hyb_ctgs = row['hybrid_mapsto'].split(';')
        for hyb_id in hyb_ctgs:
            if hyb_id not in CHR_IDS:        
                bins.write('GT_'+str(hyb_id) + '\t' + str(ctg_id) + '\t' + str(ctg_len) + '\n')        


argparser = argparse.ArgumentParser()
argparser.add_argument('--gt', help = 'path to ground truth file')
argparser.add_argument('--len_thr', type = int, help = 'minimum length threshold for contigs')
argparser.add_argument('--outdir', help = 'output directory')
argparser.add_argument('--outfile', help = 'name of output TSV file')

args = argparser.parse_args()

GT_FILE = args.gt
LEN_THR = args.len_thr
OUT_DIR = args.outdir
OUT_FILE = args.outfile

if not os.path.exists(OUT_DIR):
	os.makedirs(OUT_DIR)
bins = open(OUT_DIR + '/' + OUT_FILE, "w")

format_gt(GT_FILE, bins, LEN_THR)

