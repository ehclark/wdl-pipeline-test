version 1.0


task CopyFilesToWasabiTask {
    input {
        Array[File] source_files = []
        String source_glob = ""
        String target_dir
        Boolean no_clobber = false
    }

    String gsutil_cp_opts = "~{if no_clobber then '-n' else ''}"

    command <<<
        set -euxo pipefail
        # get the wasabi api secrets
        gcloud --project="mgb-lmm-gcp-infrast-1651079146" secrets versions access "latest" --secret=mgb-lmm-wasabi-access-key --out-file=/tmp/accesskey
        gcloud --project="mgb-lmm-gcp-infrast-1651079146" secrets versions access "latest" --secret=mgb-lmm-wasabi-secret-key --out-file=/tmp/secretkey
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
        # copy the files to wasabi
        source_file_list=~{sep=' ' source_files}
        if [ ! -z "${source_file_list}" ]
        then
            for file in ${source_file_list}
            do
                gsutil cp ~{gsutil_cp_opts} -L gsutil-cp.log "${file}" "~{target_dir}"
            done
        fi
        if [ ! -z "~{source_glob}" ]
        then
            gsutil cp ~{gsutil_cp_opts} -L gsutil-cp.log "~{source_glob}" "~{target_dir}"
        fi
        grep -v ^Source gsutil-cp.log | cut -d, -f2 > wasabi-file-list.txt
    >>>

    runtime {
        docker: "google/cloud-sdk:latest"
        memory: "4GB"
    }

    output {
        Array[String] target_files = read_lines("wasabi-file-list.txt")
        File target_files_fofn = "wasabi-file-list.txt"
    }
}