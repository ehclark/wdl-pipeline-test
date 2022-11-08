version 1.0

workflow GCRConnectivityTestWorkflow {
    input {
        String image_name
    }

    call GCRConnectivityTestTask {
        input:
            image_name = image_name
    }

    output {
        File docker_env = GCRConnectivityTestTask.docker_env
    }
}

task GCRConnectivityTestTask {
    input {
        String image_name
    }

    command <<<
        set -euxo pipefail

        /usr/bin/env > dockerenv.txt
    >>>

    runtime {
        docker: "~{image_name}"
        memory: "4GB"
    }

    output {
        File docker_env = "dockerenv.txt"
    }
}