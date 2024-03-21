version 1.0

# new comment
workflow DockstoreVersionTestingWorkflow {
    input {
        String image
        String memory
        Int cpu
        String disks
    }

    call DockstoreVersionTestingTask {
        input:
            image = image,
            memory = memory,
            cpu = cpu,
            disks = disks
    }

    output {
        File runtime_details = DockstoreVersionTestingTask.runtime_details
    }
}

task DockstoreVersionTestingTask {
    input {
        String image
        String memory
        Int cpu
        String disks
    }

    command <<<
        echo " ==== /usr/bin/env ====" > runtime_details.txt 2>&1
        /usr/bin/env >> runtime_details.txt
        echo "" >> runtime_details.txt

        echo " ==== uname -a ====" >> runtime_details.txt 2>&1
        uname -a >> runtime_details.txt
        echo "" >> runtime_details.txt
        
        echo " ==== df -H ====" >> runtime_details.txt 2>&1
        df -H >> runtime_details.txt
        echo "" >> runtime_details.txt
        
        echo " ==== /proc/cpuinfo ====" >> runtime_details.txt 2>&1
        cat /proc/cpuinfo >> runtime_details.txt
        echo "" >> runtime_details.txt
        
        echo " ==== /proc/meminfo ====" >> runtime_details.txt 2>&1
        cat /proc/meminfo >> runtime_details.txt
        echo "" >> runtime_details.txt
    >>>

    runtime {
        docker: "~{image}"
        memory: "~{memory}"
        cpu: cpu
        disks: "~{disks}"

    }

    output {
        File runtime_details = "runtime_details.txt"
    }
}