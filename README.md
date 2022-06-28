# ICGC ARGO Pre Alignment QC Workflow

This repository maintains the source code of the ICGC ARGO DNA/RNA Seq Pre Alignment QC Workflow. The workflow is written in [Nextflow](https://www.nextflow.io/) workflow language using DSLv2, with modules imported from other ICGC ARGO GitHub repositories. Specifically, here are repositories maintaining various of tools/modules:

* https://github.com/icgc-argo-workflows/argo-qc-tools
* https://github.com/icgc-argo-workflow/dna-seq-processing-tools
* https://github.com/icgc-argo-workflow/data-processing-utility-tools
* https://github.com/icgc-argo-workflow/nextflow-dna-seq-processing-tools

Each Nextflow module (including associated container image which is registered in ghcr.io) is strictly
version controlled and released independently. To ensure reproducibility the pipeline declares explicitly
which specific version of a module is to be imported.

## Major tasks performed in the workflow
* download input sequencing metadata/data from `SONG/SCORE`
* preprocess input sequencing reads (in `FASTQ` or `BAM`) into lane level (aka read group level) `FASTQs`
* collect `CollectQualityYieldMetrics` using `Picard` tool for read group
* perform `FastQC` analysis for each lane `FASTQs`
* perform `Cutadapt` analysis for each lane `FASTQs`
* perform `MultiQC` analysis to generate aggregated results
* generate `SONG` metadata for QC metrics files and upload them to `SONG/SCORE`

## Run the pipeline
To run the pipeline, please follow instruction [here](https://www.nextflow.io/docs/latest/getstarted.html#installation) to install Nextflow (version `20.10` or higher) first.

Run `0.1.0` version of the pipeline:
```
nextflow run icgc-argo/dna-seq-processing-wfs -r 0.1.0 -params-file <your_params_file.json>
```

You may need to run `nextflow pull https://github.com/icgc-argo-workflows/pre-alignment-qc` if the version `0.1.0` is new since last time the pipeline was run.

Please note that SONG/SCORE services need to be available and you have appropriate API token.

