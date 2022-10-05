version 1.0
task CopyFilesFromS3ToGCP {

    input {
        String project_name
        String source_url
        String target_url
    }

    command {
        gcloud version
        gcloud info
        gcloud auth list
        gcloud secrets versions access latest --secret="secret-id" --out-file="~/.config/gcloud/wasabi-s3-token"
    }

    runtime {
        docker: "google/cloud-sdk:latest"
        memory: "4GB"
    }
}

workflow CopyFilesFromS3ToGCPWorkflow {

    meta {
        author: "Eugene Clark"
        email: "ehclark at partners dot org"
        description: "Uses gsutil to copy files from S3 to GCP bucket"
    }
    
    input {
        String project_name
        String source_url
        String target_url
    }
    
    call CopyFilesFromS3ToGCP { 
        input: 
            project_name = project_name, 
            source_url = source_url, 
            target_url = target_url 
        }
}
