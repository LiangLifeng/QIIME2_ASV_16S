#!/bin/bash

#################################################
#    ONLY NEED TO SETING THIS ENVIRONMENT       # 
#################################################

# Activate QIIME2 environment
source activate /share/app/miniconda3/envs/qiime2-2021.11

# Variable settings
#min Samples = int(total sample * 0.1)
SILVAdatabase=/PATH/to/SILVA/silva_132_99_16S_341F_805R_classifier.qza
NCORES=6
minSamples=1
fqList=/PATH/to/fq.list
metadata=/PATH/to/metadata.txt
workDir=/PATH/to/save/result/


#################################################
#     DO NOT CHANGE ANYTHING BELOW THIS LINE    # 
#################################################

date
echo "Starting QIIME2 analysis!"
processPath=$workDir/process/
ResultPath=$workDir/Result/
mkdir $processPath $ResultPath

# 01. Import data
## Import paired-end sequencing results in Phred33 format after removing barcodes and primers

date
mkdir $processPath/01.reads_qza
if [ -e $processPath/01.reads_qza/fq.clean.reads.qza ]
then
rm -rf $processPath/01.reads_qza/fq.clean.reads.qza
fi

qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path $fqList \
  --output-path $processPath/01.reads_qza/fq.clean.reads.qza \
  --input-format PairedEndFastqManifestPhred33V2

date
echo "01 input data done !"

# 02. Quality control with DADA2: filter low-quality reads, trim sequences, remove chimeras, and denoise
date

mkdir $processPath/02.denoise
qiime dada2 denoise-paired \
  --i-demultiplexed-seqs $processPath/01.reads_qza/fq.clean.reads.qza \
  --p-max-ee-f 2 \
  --p-max-ee-r 3 \
  --p-trunc-len-f 0 \
  --p-trunc-len-r 0 \
  --p-n-threads $NCORES \
  --o-table $processPath/02.denoise/table.qza \
  --o-representative-sequences $processPath/02.denoise/rep-seqs.qza \
  --o-denoising-stats $processPath/02.denoise/denoising-stats.qza

##export data
mkdir -p $ResultPath/00.Denoise
mkdir -p $processPath/07.export

qiime tools export \
   --input-path $processPath/02.denoise/rep-seqs.qza \
   --output-path $processPath/07.export
mv $processPath/07.export/dna-sequences.fasta $ResultPath/00.Denoise/representative-sequences.fasta

qiime tools export \
   --input-path $processPath/02.denoise/table.qza \
   --output-path $processPath/07.export

biom convert -i $processPath/07.export/feature-table.biom \
    -o $ResultPath/00.Denoise/representative-sequences.Abundance.profile.xls \
    --to-tsv

qiime tools export \
   --input-path $processPath/02.denoise/denoising-stats.qza \
   --output-path $processPath/07.export

mv $processPath/07.export/stats.tsv  $ResultPath/00.Denoise/denoising-stats.tsv

date
echo "02 Denoising the reads into amplicon sequence variants done !!"
# 03. Taxonomic classification of ASVs V3-V4
#taxonomic classification
date

mkdir $processPath/03.taxonomic.classification

qiime feature-classifier classify-sklearn \
   --i-reads $processPath/02.denoise/rep-seqs.qza \
   --i-classifier $SILVAdatabase \
   --p-n-jobs $NCORES \
   --o-classification $processPath/03.taxonomic.classification/raw.taxonomy.qza 

##export data
qiime tools export \
   --input-path $processPath/03.taxonomic.classification/raw.taxonomy.qza \
   --output-path $processPath/07.export

mkdir $ResultPath/02.Taxonomy
mv  $processPath/07.export/taxonomy.tsv $ResultPath/02.Taxonomy/taxonomy.xls

date
echo "03 Assign taxonomy to ASVs done !!"


# 04. Filtering
date
mkdir $processPath/04.filter
## Filter out rare ASVs

qiime feature-table filter-features \
   --i-table $processPath/02.denoise/table.qza \
   --p-min-frequency 1 \
   --p-min-samples $minSamples \
   --o-filtered-table $processPath/04.filter/0401.dada2_table_filt.qza

## Filter contaminants and unclassified ASVs
qiime taxa filter-table \
   --i-table $processPath/04.filter/0401.dada2_table_filt.qza \
   --i-taxonomy $processPath/03.taxonomic.classification/raw.taxonomy.qza \
   --p-include "D_0__Bacteria;D_1" \
   --p-exclude mitochondria,chloroplast,D_0__Archaea,D_0__Eukaryota \
   --o-filtered-table $processPath/04.filter/0402.dada2_table_final.qza

## Subset and summarize the filtered results
qiime feature-table filter-seqs \
   --i-data $processPath/02.denoise/rep-seqs.qza \
   --i-table $processPath/04.filter/0402.dada2_table_final.qza \
   --o-filtered-data $processPath/04.filter/rep_seqs_final.qza

qiime feature-table summarize \
   --i-table $processPath/04.filter/0402.dada2_table_final.qza \
   --o-visualization $processPath/04.filter/rep_seqs_final_summary.qzv

#Exporting data
mkdir -p $ResultPath/01.ASVs
qiime tools export \
   --input-path $processPath/04.filter/0402.dada2_table_final.qza \
   --output-path $processPath/07.export

biom convert -i $processPath/07.export/feature-table.biom \
    -o $ResultPath/01.ASVs/ASVs.filter.S$minSamples\.F3.Abundance.profile.xls \
    --to-tsv
mv $processPath/07.export/feature-table.biom $ResultPath/01.ASVs/ASVs.Abundance.biom

# Relative frequency
qiime feature-table relative-frequency \
   --i-table $processPath/04.filter/0402.dada2_table_final.qza \
   --o-relative-frequency-table  $processPath/04.filter/0402.dada2_table_final_filter.S$minSamples\.F3.Relative.qza 

   qiime tools export \
      --input-path $processPath/04.filter/0402.dada2_table_final_filter.S$minSamples\.F3.Relative.qza \
      --output-path $processPath/07.export

   biom convert -i $processPath/07.export/feature-table.biom \
      -o $ResultPath/01.ASVs/ASVs_filter.S$minSamples\.F3.Relative.Abundance.xls \
      --to-tsv

qiime tools export \
   --input-path $processPath/04.filter/rep_seqs_final.qza \
   --output-path $processPath/07.export

mv $processPath/07.export/dna-sequences.fasta $ResultPath/01.ASVs/ASVs.fasta

qiime tools export \
  --input-path $processPath/04.filter/rep_seqs_final_summary.qzv \
  --output-path $ResultPath/01.ASVs/summary/

# Extract taxonomic level abundance profiles
date
TaxonomyLevel=(Phylum Class Order Family Genus Species )
TaxonomyOrder=(2 3 4 5 6 7 )

for index in ${!TaxonomyLevel[*]}; do 
   qiime taxa collapse \
   --i-table $processPath/04.filter/0402.dada2_table_final.qza  \
   --i-taxonomy $processPath/03.taxonomic.classification/raw.taxonomy.qza \
   --o-collapsed-table $processPath/03.taxonomic.classification/${TaxonomyLevel[$index]}_table.qza \
   --p-level ${TaxonomyOrder[$index]}

   qiime feature-table filter-features \
      --i-table  $processPath/03.taxonomic.classification/${TaxonomyLevel[$index]}_table.qza \
      --p-min-frequency 3 \
      --p-min-samples $minSamples \
      --o-filtered-table  $processPath/03.taxonomic.classification/${TaxonomyLevel[$index]}_filter.S$minSamples\.F3.table.qza
  
  qiime feature-table relative-frequency \
   --i-table $processPath/03.taxonomic.classification/${TaxonomyLevel[$index]}_filter.S$minSamples\.F3.table.qza \
   --o-relative-frequency-table  $processPath/03.taxonomic.classification/${TaxonomyLevel[$index]}_filter.S$minSamples\.F3.Relative.qza 

   qiime tools export \
      --input-path $processPath/03.taxonomic.classification/${TaxonomyLevel[$index]}_filter.S$minSamples\.F3.table.qza \
      --output-path $processPath/07.export

   biom convert -i $processPath/07.export/feature-table.biom \
      -o $ResultPath/02.Taxonomy/${TaxonomyLevel[$index]}_filter.S$minSamples\.F3.Abundance.xls \
      --to-tsv

   qiime tools export \
      --input-path $processPath/03.taxonomic.classification/${TaxonomyLevel[$index]}_filter.S$minSamples\.F3.Relative.qza \
      --output-path $processPath/07.export

   biom convert -i $processPath/07.export/feature-table.biom \
      -o $ResultPath/02.Taxonomy/${TaxonomyLevel[$index]}_filter.S$minSamples\.F3_Relative.Abundance.xls \
      --to-tsv


  
  echo "${TaxonomyLevel[$index]} is done!"
done

date
echo "04 Filtering resultant table done !!!!"

