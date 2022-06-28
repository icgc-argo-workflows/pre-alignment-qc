#!/usr/bin/env nextflow

/*
  Copyright (C) 2022,  ICGC ARGO

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU Affero General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Affero General Public License for more details.

  You should have received a copy of the GNU Affero General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.

  Authors:
    Linda Xiang
*/

nextflow.enable.dsl = 2
version = '0.1.0'  // package version
name = 'pre-alignment-qc'

// universal params go here, change default value as needed
params.container = ""
params.container_registry = ""
params.container_version = ""
params.cpus = 1
params.mem = 1  // GB
params.publish_dir = ""  // set to empty string will disable publishDir

// tool specific parmas go here, add / change as needed
params.study_id = ""
params.analysis_id = ""
params.analysis_metadata = "NO_FILE"
params.experiment_info_tsv = "NO_FILE1"
params.read_group_info_tsv = "NO_FILE2"
params.file_info_tsv = "NO_FILE3"
params.extra_info_tsv = "NO_FILE4"
params.sequencing_files = []
params.max_retries = 5  // set to 0 will disable retry
params.first_retry_wait_time = 1  // in seconds
params.tempdir = "NO_DIR"
params.cleanup = true
params.genome_annotation = ""
params.genome_build = ""

params.song_url = ""
params.score_url = ""
params.api_token = ""
params.download = [:]
params.seqDataToLane = [:]
params.fastqc = [:]
params.cutadapt = [:]
params.multiqc = [:]
params.payloadGen = [:]
params.uploadQc = [:]

download_params = [
    'cpus': params.cpus,
    'mem': params.mem,
    'max_retries': params.max_retries,
    'first_retry_wait_time': params.first_retry_wait_time,
    'song_url': params.song_url,
    'score_url': params.score_url,
    'api_token': params.api_token,
    *:(params.download ?: [:])
]

seqDataToLane_params = [
    'cpus': params.cpus,
    'mem': params.mem,
    'reads_max_discard_fraction': -1,
    'publish_dir': params.publish_dir,
    *:(params.seqDataToLane ?: [:])
]

payloadGen_params = [
    'cpus': params.cpus,
    'mem': params.mem,
    'publish_dir': params.publish_dir,
    *:(params.payloadGen ?: [:])
]

uploadQc_params = [
    'max_retries': params.max_retries,
    'first_retry_wait_time': params.first_retry_wait_time,
    'cpus': params.cpus,
    'mem': params.mem,
    'song_url': params.song_url,
    'score_url': params.score_url,
    'api_token': params.api_token,
    *:(params.uploadQc ?: [:])
]

include { SongScoreDownload as dnld } from './wfpr_modules/github.com/icgc-argo/nextflow-data-processing-utility-tools/song-score-download@2.6.2/main.nf' params(download_params)
include { payloadGenSeqExperiment as pGenExp } from './wfpr_modules/github.com/icgc-argo-workflows/data-processing-utility-tools/payload-gen-seq-experiment@0.5.0.1/main.nf' params(payloadGen_params)
include { seqDataToLaneFastq as toLane } from './wfpr_modules/github.com/icgc-argo-workflows/dna-seq-processing-tools/seq-data-to-lane-fastq@0.2.0/main.nf' params(seqDataToLane_params)
include { cutadapt } from './wfpr_modules/github.com/icgc-argo-workflows/argo-qc-tools/cutadapt@0.2.0/main.nf' params([*:params, 'cleanup': false])
include { fastqc } from './wfpr_modules/github.com/icgc-argo-workflows/argo-qc-tools/fastqc@0.2.0/main.nf' params([*:params, 'cleanup': false])
include { multiqc } from './wfpr_modules/github.com/icgc-argo-workflows/argo-qc-tools/multiqc@0.1.0/main.nf' params([*:params, 'cleanup': false])
include { payloadGenQc as pGenQc } from './wfpr_modules/github.com/icgc-argo-workflows/data-processing-utility-tools/payload-gen-qc@0.1.0/main.nf' params(payloadGen_params)
include { SongScoreUpload as upQc} from './wfpr_modules/github.com/icgc-argo/nextflow-data-processing-utility-tools/song-score-upload@2.7.0/main.nf' params(uploadQc_params)
include { cleanupWorkdir as cleanup } from './wfpr_modules/github.com/icgc-argo-workflows/data-processing-utility-tools/cleanup-workdir@1.0.0.1/main.nf'


// please update workflow code as needed
workflow PreAlignmentQcWf {
  take:  // update as needed
    study_id
    analysis_id
    analysis_metadata
    experiment_info_tsv
    read_group_info_tsv
    file_info_tsv
    extra_info_tsv
    sequencing_files


  main:  // update as needed
    // detect local mode or not
    local_mode = false
    if ((!analysis_metadata.startsWith("NO_FILE") || !experiment_info_tsv.startsWith("NO_FILE")) && sequencing_files.size() > 0){
        local_mode = true
        if (!params.publish_dir) {
            exit 1, "You specified local sequencing data as input, please also set `params.publish_dir` to keep the output."
        }
        log.info "Run the workflow using local input sequencing data, results will be in: ${params.publish_dir}"

        if (!analysis_metadata.startsWith("NO_FILE")) {
            if (!experiment_info_tsv.startsWith("NO_FILE") ||
                    !read_group_info_tsv.startsWith("NO_FILE") ||
                    !file_info_tsv.startsWith("NO_FILE") ||
                    !extra_info_tsv.startsWith("NO_FILE")
            )  {
                log.info "Use analysis metadata JSON as input, will ignore input: 'experiment_info_tsv', 'read_group_info_tsv', 'file_info_tsv', 'extra_info_tsv'"
            }
            analysis_metadata = file(analysis_metadata)
        } else if (!experiment_info_tsv.startsWith("NO_FILE") &&
                    !read_group_info_tsv.startsWith("NO_FILE") &&
                    !file_info_tsv.startsWith("NO_FILE") &&
                    !extra_info_tsv.startsWith("NO_FILE")
            ) {
            pGenExp(
                file(experiment_info_tsv),
                file(read_group_info_tsv),
                file(file_info_tsv),
                file(extra_info_tsv)
            )
            analysis_metadata = pGenExp.out.payload
        } else {
            exit 1, "To run the workflow using local inputs, please specify metadata in JSON using params.analysis_metadata or metadata in TSVs using params.experiment_info_tsv, params.read_group_info_tsv, params.file_info_tsv and params.extra_info_tsv"
        }

        sequencing_files = Channel.fromPath(sequencing_files)
    } else if (study_id && analysis_id) {
        // download files and metadata from song/score (analysis type: sequencing_experiment)
        log.info "Run the workflow using input sequencing data from SONG/SCORE, alignment results will be uploaded to SONG/SCORE as well"
        dnld(study_id, analysis_id)
        analysis_metadata = dnld.out.analysis_json
        sequencing_files = dnld.out.files
    } else {
        exit 1, "To use sequencing data from SONG/SCORE as input, please provide `params.study_id`, `params.analysis_id` and other SONG/SCORE params.\n" +
            "Or please provide `params.analysis_metadata` (or `params.experiment_info_tsv`, `params.read_group_info_tsv`, `params.file_info_tsv` and `params.extra_info_tsv`) and `params.sequencing_files` from local files as input."
    }

    // preprocessing input data (BAM or FASTQ) into read group level fastq
    toLane(analysis_metadata, sequencing_files.collect())

    // create input channels for fastqc
    toLane.out.file_pair_map_csv
    .splitCsv(header:true)
    .map{ row-> 
              if (row.file_r2 != "No_File") {
                tuple(row.read_group_id, tuple(file(row.file_r1), file(row.file_r2))) 
              }
              else {
                tuple(row.read_group_id, tuple(file(row.file_r1)))
              }
        }
    .set { fastqc_ch }
    
    // perform fastqc
    fastqc(fastqc_ch)

    // create input channels for cutadpat 
    toLane.out.file_pair_map_csv
    .splitCsv(header:true)
    .map{ row-> tuple(row.read_group_id, file(row.file_r1), file(row.file_r2)) }
    .set { cutadapt_ch }

    // perform cutadpat
    cutadapt(cutadapt_ch)

    // perform multiqc
    multiqc(fastqc.out.fastqc_results.concat(cutadapt.out.cutadapt_log).collect())

    // generate payload
    pGenQc(
      fastqc.out.fastqc_tar.concat(cutadapt.out.cutadapt_tar, multiqc.out.multiqc_tar).collect(), analysis_metadata, 
      params.genome_annotation, params.genome_build, name, version)    

    // upload QC files and metadata to song/score
    if (!local_mode) {
        upQc(study_id, pGenQc.out.payload, pGenQc.out.files_to_upload.collect(), '')
    }

    if (params.cleanup && !local_mode) {
      cleanup(
        sequencing_files.concat(toLane.out, cutadapt.out, fastqc.out.fastqc_tar, multiqc.out.multiqc_tar, pGenQc.out).collect(),
          upQc.out.analysis_id) // wait until unQc is done  
    } else if (params.cleanup && local_mode) {
      cleanup(
        sequencing_files.concat(toLane.out, cutadapt.out, fastqc.out.fastqc_tar, multiqc.out.multiqc_tar, pGenQc.out).collect(), 
        true)
    }


  emit:  // update as needed
    file_pair_map = toLane.out.file_pair_map_csv
    payload = pGenQc.out.payload
    multiqc_report = multiqc.out.multiqc_html

}


// this provides an entry point for this main script, so it can be run directly without clone the repo
// using this command: nextflow run <git_acc>/<repo>/<pkg_name>/<main_script>.nf -r <pkg_name>.v<pkg_version> --params-file xxx
workflow {
  PreAlignmentQcWf(
    params.study_id,
    params.analysis_id,
    params.analysis_metadata,
    params.experiment_info_tsv,
    params.read_group_info_tsv,
    params.file_info_tsv,
    params.extra_info_tsv,
    params.sequencing_files
  )
}