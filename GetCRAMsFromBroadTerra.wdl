version 1.0

import "tasks/CopyFilesToWasabi.wdl"

workflow GetCRAMsFromBroadTerraWorkflow {

    meta {
        author: "Eugene Clark"
        email: "ehclark at partners dot org"
        description: "Workflow that imports CRAMs from a specific run from Broad Terra workspace bucket to Wasabi"
    }
    
    input {
        String run_id
        String broad_bucket_name = "terra-integration-lz-test"
        String broad_bucket_path_prefix = "/runs/"
        String broad_bucket_path_suffix = "/crams/"
        String wasabi_bucket_name = "gcp-integration-test"
        String wasabi_bucket_path_prefix = "/runs/"
        String wasabi_bucket_path_suffix = "/crams/"
    }

    call CopyFilesToWasabi.CopyFilesToWasabiTask {
        input:
            source_glob = "gs://" + broad_bucket_name + broad_bucket_path_prefix + run_id + broad_bucket_path_suffix + "**/*.cram",
            target_dir = "s3://" + wasabi_bucket_name + wasabi_bucket_path_prefix + run_id + wasabi_bucket_path_suffix,
            no_clobber = true
    }
}
