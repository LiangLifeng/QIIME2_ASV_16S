### QIIME2 Amplicon Sequence Variant (ASV) Analysis Tutorial

This tutorial will guide you through using QIIME2 to analyze amplicon sequencing data to obtain amplicon sequence variants (ASVs) and their taxonomy. By following this guide, you'll be able to set up the software environment and databases, configure your data, and perform the analysis with a single script.

#### Software and Database Requirements

1. **QIIME2** (version 2021.11 or later recommended)
   - Installation instructions: [QIIME2 Installation Guide](https://docs.qiime2.org/2024.5/install/)
   
2. **biom** (command-line tool for ecological data)
   - Installation: Usually included with QIIME2 or can be installed via conda.
   
3. **Reference database for taxonomic classification** (e.g., SILVA 132 99%)
   - Download and setup: [QIIME2 Data Resources](https://docs.qiime2.org/2024.5/data-resources/)

#### Step 1: Prepare Fastq Data and Metadata

##### 1.1 Fastq Data List (`fqList`)

QIIME2 supports various formats of fastq files. Below is an example of how to format a manifest file for paired-end reads with absolute paths. For more details, refer to the [QIIME2 Importing Tutorial](https://docs.qiime2.org/2024.5/tutorials/importing/#sequence-data-with-sequence-quality-information-i-e-fastq).

**Example Manifest File:**

```
sample-id       forward-absolute-filepath               reverse-absolute-filepath
Sample1         /path/to/sample1_1.fq.gz                /path/to/sample1_2.fq.gz
Sample2         /path/to/sample2_1.fq.gz                /path/to/sample2_2.fq.gz
Sample3         /path/to/sample3_1.fq.gz                /path/to/sample3_2.fq.gz
```

##### 1.2 Metadata File (`metadata`)

QIIME2 supports diverse metadata formats. Below is a basic example that contains only group information. For more details, refer to the [QIIME2 Metadata Tutorial](https://docs.qiime2.org/2024.5/tutorials/metadata/).

**Example Metadata File:**

```
sample-id       Group
#q2:types       categorical
Sample1         groupA
Sample2         groupB
Sample3         groupC
```

#### Step 2: Set Variables

Open the `iMomics.16S.qiime2.sh` script and set the QIIME2 environment and work variables as follows:
- **SILVAdatabase**: Path to SILVA QIIME2 classifier.qza
- **NCORES**: Number of cores to use for parallel processing
- **minSamples**: Minimum number of samples an ASV needs to be present in to be retained
- **fqList**: Path to the manifest file containing paths to your paired-end FASTQ files
- **metadata**: Path to the sample metadata file (optional)
- **workDir**: Path to a directory for storing intermediate and result files

#### Step 3: Run the Main Shell Script

Execute the script to perform the analysis:

```bash
sh Momics.16S.qiime2.sh
```

This script will guide you through the entire analysis process, including data import, quality control, denoising, taxonomic classification, and filtering.

By following these steps, you should be able to complete your amplicon sequence variant analysis using QIIME2 efficiently. If you encounter any issues, refer to the QIIME2 documentation or seek help from the QIIME2 community.