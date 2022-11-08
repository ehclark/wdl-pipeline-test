version 1.0

workflow DepthOfCoverageWorkflow {
    input {
        String wes_or_wgs
        String sample_name
        File ref_fasta
        File ref_fasta_index
        File ref_dict
        File bam
        File bai
        File roi_all_bed
        Array[RoiAndRefGeneFilePair] roi_genes
        File gene_names
        Int gatk_max_heap_gb = 31
        Int gatk_disk_size_gb = 20
    }

    if (wes_or_wgs == "WGS") {
        call DepthOfCoverageTaskNOBED {
            input:
                sample_name = sample_name,
                ref_fasta = ref_fasta,
                ref_fasta_index = ref_fasta_index,
                ref_dict = ref_dict,
                bam = bam,
                bai = bai,
                gatk_max_heap_gb = gatk_max_heap_gb,
                gatk_disk_size_gb = gatk_disk_size_gb
        }
    }

    call DepthOfCoverageTaskWGSROI {
        input:
            sample_name = sample_name,
            ref_fasta = ref_fasta,
            ref_fasta_index = ref_fasta_index,
            ref_dict = ref_dict,
            bam = bam,
            bai = bai,
            bed = roi_all_bed,
            gatk_max_heap_gb = gatk_max_heap_gb,
            gatk_disk_size_gb = gatk_disk_size_gb
    }

    scatter (roi_gene in roi_genes) {
        call DepthOfCoverageBED {
            input:
                sample_name = sample_name,
                ref_fasta = ref_fasta,
                ref_fasta_index = ref_fasta_index,
                ref_dict = ref_dict,
                bam = bam,
                bai = bai,
                bed = roi_gene.roi_bed,
                refseq_genes = roi_gene.ref_gene,
                gatk_max_heap_gb = gatk_max_heap_gb,
                gatk_disk_size_gb = gatk_disk_size_gb
        }
    }

    call DepthOfCoverageSummary {
        input:
            sample_gene_summaries = DepthOfCoverageBED.sample_gene_summary,
            sample_interval_summary = DepthOfCoverageTaskWGSROI.sample_interval_summary,
            gene_output_file = sample_name + ".cov.merge.sample_gene_summary",
            mt_output_file = sample_name + ".cov.merge.sample_mt_summary",
            gene_names = gene_names
    }

    output {
        File? nobed_sample_summary = DepthOfCoverageTaskNOBED.sample_summary
        File? nobed_sample_statistics = DepthOfCoverageTaskNOBED.sample_statistics
        File wgsroi_sample_interval_summary = DepthOfCoverageTaskWGSROI.sample_interval_summary
        File wgsroi_sample_interval_statistics = DepthOfCoverageTaskWGSROI.sample_interval_statistics
        File wgsroi_sample_statistics = DepthOfCoverageTaskWGSROI.sample_statistics
        File wgsroi_sample_summary = DepthOfCoverageTaskWGSROI.sample_summary
        File wgsroi_sample_cumulative_coverage_counts = DepthOfCoverageTaskWGSROI.sample_cumulative_coverage_counts
        File wgsroi_sample_cumulative_coverage_proportions = DepthOfCoverageTaskWGSROI.sample_cumulative_coverage_proportions
        File mt_summary = DepthOfCoverageSummary.mt_summary
        File gene_summary = DepthOfCoverageSummary.gene_summary
        File gene_summary_unknown = DepthOfCoverageSummary.gene_summary_unknown
        File gene_summary_entrez = DepthOfCoverageSummary.gene_summary_entrez
    }
}

struct RoiAndRefGeneFilePair {
    File roi_bed
    File ref_gene
}

task DepthOfCoverageTaskNOBED {
    input {
        String sample_name
        File ref_fasta
        File ref_fasta_index
        File ref_dict
        File bam
        File bai
        Int gatk_max_heap_gb
        Int gatk_disk_size_gb
    }

    command <<<
        set -euxo pipefail
        mkdir cov_out
        java -Xmx~{gatk_max_heap_gb}g -jar /usr/GenomeAnalysisTK.jar -T DepthOfCoverage \
            -I "~{bam}" \
            -ct 8 -ct 15 -ct 30 \
            -R "~{ref_fasta}" \
            -dt BY_SAMPLE -dcov 1000 -l INFO --omitDepthOutputAtEachBase --omitLocusTable --minBaseQuality 10 --minMappingQuality 17 --countType COUNT_FRAGMENTS_REQUIRE_SAME_BASE \
            -o "cov_out/~{sample_name}.cov.nobed" \
            -omitIntervals
        ls -l cov_out
    >>>

    runtime {
        docker: "broadinstitute/gatk3:3.7-0"
        memory: "~{gatk_max_heap_gb + 4}GB"
        cpu: floor(gatk_max_heap_gb / 4)
        disks: "local-disk ~{gatk_disk_size_gb} SSD"
    }

    output {
        File sample_statistics = "cov_out/~{sample_name}.cov.nobed.sample_statistics"
        File sample_summary = "cov_out/~{sample_name}.cov.nobed.sample_summary"
    }
}

task DepthOfCoverageTaskWGSROI {
    input {
        String sample_name
        File ref_fasta
        File ref_fasta_index
        File ref_dict
        File bam
        File bai
        File bed
        Int gatk_max_heap_gb
        Int gatk_disk_size_gb
    }

    command <<<
        set -euxo pipefail
        mkdir cov_out
        java -Xmx~{gatk_max_heap_gb}g -jar /usr/GenomeAnalysisTK.jar -T DepthOfCoverage \
            -I "~{bam}" \
            -ct 8 -ct 15 \
            -R "~{ref_fasta}" \
            -dt BY_SAMPLE -dcov 1000 -l INFO --omitDepthOutputAtEachBase --minBaseQuality 10 --minMappingQuality 17 --countType COUNT_FRAGMENTS_REQUIRE_SAME_BASE \
            --printBaseCounts \
            -o "cov_out/~{sample_name}.cov.roibed" \
            -L "~{bed}"
        ls -l cov_out
    >>>

    runtime {
        docker: "broadinstitute/gatk3:3.7-0"
        memory: "~{gatk_max_heap_gb + 4}GB"
        cpu: floor(gatk_max_heap_gb / 4)
        disks: "local-disk ~{gatk_disk_size_gb} SSD"
    }

    output {
        File sample_interval_summary = "cov_out/~{sample_name}.cov.roibed.sample_interval_summary"
        File sample_interval_statistics = "cov_out/~{sample_name}.cov.roibed.sample_interval_statistics"
        File sample_statistics = "cov_out/~{sample_name}.cov.roibed.sample_statistics"
        File sample_summary = "cov_out/~{sample_name}.cov.roibed.sample_summary"
        File sample_cumulative_coverage_counts = "cov_out/~{sample_name}.cov.roibed.sample_cumulative_coverage_counts"
        File sample_cumulative_coverage_proportions = "cov_out/~{sample_name}.cov.roibed.sample_cumulative_coverage_proportions"
    }
}


task DepthOfCoverageBED {
    input {
        String sample_name
        File ref_fasta
        File ref_fasta_index
        File ref_dict
        File bam
        File bai
        File roi_bed
        File ref_gene
        String refg_idx = sub(basename(roi_bed), "[^0-9]", "")
        Int gatk_max_heap_gb
        Int gatk_disk_size_gb
    }

    command <<<
        set -euxo pipefail
        mkdir cov_out
        java -Xmx~{gatk_max_heap_gb}g -jar /usr/GenomeAnalysisTK.jar -T DepthOfCoverage \
            -I "~{bam}" \
            -ct 8 -ct 15 -ct 30 \
            -R "~{ref_fasta}" \
            -dt BY_SAMPLE -dcov 1000 -l INFO --omitDepthOutputAtEachBase --minBaseQuality 10 --minMappingQuality 17 --countType COUNT_FRAGMENTS_REQUIRE_SAME_BASE \
            --printBaseCounts \
            -o "cov_out/~{sample_name}.cov.refg${refg}" \
            -L "~{roi_bed}" \
            --calculateCoverageOverGenes:REFSEQ "~{ref_gene}"
        ls -l cov_out
    >>>

    runtime {
        docker: "broadinstitute/gatk3:3.7-0"
        memory: "~{gatk_max_heap_gb + 4}GB"
        cpu: floor(gatk_max_heap_gb / 4)
        disks: "local-disk ~{gatk_disk_size_gb} SSD"
    }

    output {
        File sample_gene_summary = "cov_out/~{sample_name}.cov.refg~{refg_idx}.sample_gene_summary"
        File sample_interval_summary = "cov_out/~{sample_name}.cov.refg~{refg_idx}.sample_interval_summary"
        File sample_interval_statistics = "cov_out/~{sample_name}.cov.refg~{refg_idx}.sample_interval_statistics"
        File sample_statistics = "cov_out/~{sample_name}.cov.refg~{refg_idx}.sample_statistics"
        File sample_summary = "cov_out/~{sample_name}.cov.refg~{refg_idx}.sample_summary"
        File sample_cumulative_coverage_counts = "cov_out/~{sample_name}.cov.refg~{refg_idx}.sample_cumulative_coverage_counts"
        File sample_cumulative_coverage_proportions = "cov_out/~{sample_name}.cov.refg~{refg_idx}.sample_cumulative_coverage_proportions"
    }
}

task DepthOfCoverageSummary {
    input {
        Array[File] sample_gene_summaries
        File sample_interval_summary
        File gene_names
        String gene_output_file
        String mt_output_file
    }

    command <<<
        set -euxo pipefail

        head -1 "~{sample_gene_summaries[0]}" > "~{gene_output_file}"
        for file in ~{sep=' ' sample_gene_summaries}; do 
            tail -n +2 "$file" | grep -v UNKNOWN >> "~{gene_output_file}"
        done
        cat ~{sep=' ' sample_gene_summaries} | grep UNKNOWN > "~{gene_output_file}.UNKNOWN"

        head -1 "~{sample_interval_summary}" > "~{mt_output_file}"
        grep ^MT "~{sample_interval_summary}" >> "~{mt_output_file}"

        $MGBPMBIOFXPATH/DepthOfCoverage/add_entrez.py -i "~{gene_output_file}" -m "~{gene_names}"
    >>>

    runtime {
        docker: "mgbpmbiofx/base:latest"
        memory: "4GB"
    }

    output {
        File gene_summary = gene_output_file
        File gene_summary_unknown = "~{gene_output_file}.UNKNOWN"
        File gene_summary_entrez = gene_output_file + "_entrez.txt"
        File mt_summary = mt_output_file
    }
}