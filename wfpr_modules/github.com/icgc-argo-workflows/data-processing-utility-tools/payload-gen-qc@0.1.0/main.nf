#!/usr/bin/env nextflow

/*
  Copyright (C) 2021,  Ontario Institute for Cancer Research

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

/********************************************************************/
/* this block is auto-generated based on info from pkg.json where   */
/* changes can be made if needed, do NOT modify this block manually */
nextflow.enable.dsl = 2
version = '0.1.0'  // package version

container = [
    'ghcr.io': 'ghcr.io/icgc-argo-workflows/data-processing-utility-tools.payload-gen-qc'
]
default_container_registry = 'ghcr.io'
/********************************************************************/


// universal params go here
params.container_registry = ""
params.container_version = ""
params.container = ""

params.cpus = 1
params.mem = 1  // GB
params.publish_dir = ""  // set to empty string will disable publishDir


// tool specific parmas go here, add / change as needed
params.files_to_upload = ""
params.metadata_analysis = ""
params.wf_name = ""
params.wf_version = ""
params.genome_annotation = ""
params.genome_build = ""


process payloadGenQc {
  container "${params.container ?: container[params.container_registry ?: default_container_registry]}:${params.container_version ?: version}"
  publishDir "${params.publish_dir}/${task.process.replaceAll(':', '_')}", mode: "copy", enabled: params.publish_dir ? true : false

  cpus params.cpus
  memory "${params.mem} GB"

  input:  // input, make update as needed
    path files_to_upload
    path metadata_analysis
    val genome_annotation
    val genome_build
    val wf_name
    val wf_version

  output:  // output, make update as needed
    path "*.payload.json", emit: payload
    path "out/*", emit: files_to_upload

  script:
    // add and initialize variables here as needed

    """
    main.py \
      -f ${files_to_upload} \
      -a ${metadata_analysis} \
      -g "${genome_annotation}" \
      -b "${genome_build}" \
      -w "${wf_name}" \
      -r ${workflow.runName} \
      -s ${workflow.sessionId} \
      -v ${wf_version}

    """
}


// this provides an entry point for this main script, so it can be run directly without clone the repo
// using this command: nextflow run <git_acc>/<repo>/<pkg_name>/<main_script>.nf -r <pkg_name>.v<pkg_version> --params-file xxx
workflow {
  payloadGenQc(
    Channel.fromPath(params.files_to_upload).collect(),
    file(params.metadata_analysis),
    params.genome_annotation,
    params.genome_build,
    params.wf_name,
    params.wf_version
  )
}
