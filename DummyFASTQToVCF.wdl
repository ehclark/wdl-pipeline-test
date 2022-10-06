version 1.0

task DummyFASTQToVCF {

    input {
        Array[File] fastq_files
        File source_vcf
        String output_vcfname
    }

    command <<<
        set -euxo pipefail
        for x in ~{sep=' ' fastq_files}
        do
            [ ! -f "${x}" ] && exit 1
        done

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

workflow DummyFASTQToVCFWorkflow {

    meta {
        author: "Eugene Clark"
        email: "ehclark at partners dot org"
        description: "Dummy workflow that takes in a list of FASTQs and copies a static VCF to the output"
    }
    
    input {
        Array[File] fastq_files
        File source_vcf
        String output_vcfname
    }
    
    call DummyFASTQToVCF { 
        input: 
            fastq_files = fastq_files, 
            source_vcf = source_vcf, 
            output_vcfname = output_vcfname 
        }

    output {
        File output_vcf = DummyFASTQToVCF.output_vcf
    }
}
