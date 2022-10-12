version 1.0

task CopyFilesFromWasabiTask {
    input {
        Array[String] source_files
    }

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
        # for each input file
        mkdir targetdir
        for file in ~{sep=' ' source_files}
        do
            gsutil cp -n -L gsutil-cp.log "$file" ./targetdir/
        done
    >>>

    runtime {
        docker: "google/cloud-sdk:latest"
        memory: "4GB"
    }

    output {
        Array[File] target_files = glob("./targetdir/*")
    }
}