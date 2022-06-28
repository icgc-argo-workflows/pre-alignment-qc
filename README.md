# ICGC ARGO Pre Alignment QC Workflow

This repository maintains the source code of the ICGC ARGO Pre Alignment QC Workflow for DNA/RNA Seq. The workflow is written in [Nextflow](https://www.nextflow.io/) workflow language using DSLv2, with modules imported from other ICGC ARGO GitHub repositories. Specifically, here are repositories maintaining various of tools/modules:

* https://github.com/icgc-argo-workflows/argo-qc-tools
* https://github.com/icgc-argo-workflows/dna-seq-processing-tools
* https://github.com/icgc-argo-workflows/data-processing-utility-tools
* https://github.com/icgc-argo-workflows/nextflow-dna-seq-processing-tools

Each Nextflow module (including associated container image which is registered in ghcr.io) is strictly
version controlled and released independently. To ensure reproducibility the pipeline declares explicitly
which specific version of a module is to be imported.

## Major tasks performed in the workflow
* download input sequencing metadata/data from data center using [SONG/SCORE client tools](https://docs.icgc-argo.org/docs/submission/submitting-molecular-data#data-submission-client-configuration)
* preprocess input sequencing reads (in `FASTQ` or `BAM`) into `FASTQ` file(s) per read group
* perform `FastQC` analysis for `FASTQ` file(s) per read group
* perform `Cutadapt` analysis for `FASTQ` file(s) per read group
* perform `MultiQC` analysis to generate aggregated results
* generate `SONG` metadata for all collected QC metrics files and upload them to `SONG/SCORE`

## Inputs
### Local mode
- study_id
- analysis_metadata
- sequencing_files

### RDPC mode
- study_id
- analysis_id
- song_url
- score_url
- api_token

## Outputs
- file_pair_map: CSV file with each row contains 3 columns: `read_group_id`, `file_r1`, `file_r2`, which represent information for each read group
- payload: Payload contains metadata for all QC files
- multiqc_report: HTML report file `multiqc_report.html`


## Run the pipeline
To run the pipeline, please follow instruction [here](https://www.nextflow.io/docs/latest/getstarted.html#installation) to install Nextflow (version `20.10` or higher) first. 
With inputs prepared, you should be able to run the workflow using the following command. Please replace the params file with a real one (with all required parameters and input files). Example params file `example-params.json` can be found in the workflow root folder.

Run `0.1.0` version of the pipeline:
```
nextflow run icgc-argo-workflows/pre-alignment-qc/main.nf -r 0.1.0 -params-file <your_params_file.json>
```

You may need to run `nextflow pull https://github.com/icgc-argo-workflows/pre-alignment-qc` if the version `0.1.0` is new since last time the pipeline was run.

Please note that SONG/SCORE services need to be available and you have appropriate API token.

