version 1.0

task ImportFilesFromWasabi {
    input {
        Array[String] fastq_files_in
    }

    command <<<
        set -euxo pipefail
        # get the wasabi api secrets
        TERRA_PROJECT_ID=$(gcloud config get project)
        gcloud config set project "mgb-lmm-gcp-infrast-1651079146"
        gcloud secrets versions access "latest" --secret=mgb-lmm-wasabi-access-key --out-file=/tmp/accesskey
        gcloud secrets versions access "latest" --secret=mgb-lmm-wasabi-secret-key --out-file=/tmp/secretkey
        gcloud config set project "${TERRA_PROJECT_ID}"
        # construct the .boto file
        echo "[Credentials]" > ~/.boto
        echo -n "aws_access_key_id = " >> ~/.boto
        cat /tmp/accesskey >> ~/.boto
        echo "" >> ~/.boto
        echo -n "aws_secret_access_key = " >> ~/.boto
        cat /tmp/secretkey >> ~/.boto
        echo "" >> ~/.boto
        echo "s3_host = s3.us-east-1.wasabisys.com" >> ~/.boto
        rm /tmp/accesskey /tmp/secretkey
        # for each input file
        for file in ~{sep=' ' fastq_files_in}
        do
            if [[ "$file" = s3://* ]]
            then
                filename=$(basename "$file")
                gsutil cp -n "$file" "$filename"
                echo -n "$filename " >> importedfilelist.txt
            else
                echo -n "$file " >> importedfilelist.txt
            fi
        done
    >>>

    runtime {
        docker: "google/cloud-sdk:latest"
        memory: "4GB"
    }

    output {
        Array[File] fastq_files_out = glob(read_string("importedfilelist.txt"))
    }
}

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
        Array[String] fastq_files
        File source_vcf
        String output_vcfname
    }

    call ImportFilesFromWasabi {
        input:
            fastq_files_in = fastq_files
    }
    
    call DummyFASTQToVCF { 
        input: 
            fastq_files = ImportFilesFromWasabi.fastq_files_out, 
            source_vcf = source_vcf, 
            output_vcfname = output_vcfname 
    }

    output {
        File output_vcf = DummyFASTQToVCF.output_vcf
    }
}
