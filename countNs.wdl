version 1.0

workflow count_total_assembly_gaps {
    input {
        File assembly_fasta
    }

    call calculate_gap_bases {
        input:
            assembly_fasta = assembly_fasta
    }

    output {
        Int total_gaps = calculate_gap_bases.total_ns
    }
}

task calculate_gap_bases {
    input {
        File assembly_fasta
    }

    command {
        gzip -cd ${assembly_fasta} | grep -v "^>" | tr -d -c 'Nn' | wc -c > gaps.txt
    }

    output {
        Int total_ns = read_int("gaps.txt")
    }

    runtime {
        docker: "debian:bullseye"
        preemptible: 3
    }
}
