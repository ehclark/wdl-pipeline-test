version 1.0

import "tasks/CopyFilesFromWasabi.wdl"
import "tasks/CopyFilesToWasabi.wdl"

task DummyVariantCalling {

    input {
        File cram_file
        File source_vcf
        String output_vcfname
    }

    command <<<
        set -euxo pipefail
        [ ! -f "~{cram_file}" ] && exit 1
        cp "~{source_vcf}" "~{output_vcfname}"
    >>>

    output {
        File output_vcf = output_vcfname
    }

    runtime {
        docker: "ubuntu:latest"
        memory: "4GB"
    }
}

workflow DummyVariantCallingWorkflow {

    meta {
        author: "Eugene Clark"
        email: "ehclark at partners dot org"
        description: "Dummy workflow that takes in a CRAM and copies a static VCF to the output"
    }
    
    input {
        String cram_file
        File source_vcf
        String output_vcfname
        String output_dir
    }

    call CopyFilesFromWasabi.CopyFilesFromWasabiTask {
        input:
            source_files = [cram_file]
    }
    
    call DummyVariantCalling { 
        input: 
            cram_file = CopyFilesFromWasabiTask.target_files[0], 
            source_vcf = source_vcf, 
            output_vcfname = output_vcfname 
    }

    call CopyFilesToWasabi.CopyFilesToWasabiTask {
        input:
            source_files = [DummyVariantCalling.output_vcf],
            target_dir = output_dir
    }

    output {
        File output_vcf = DummyVariantCalling.output_vcf
    }
}
