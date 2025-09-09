#!/bin/bash

# Comprehensive benchmarking script for My Scratch Pad
# Performs 2-minute performance analysis of Docker vs VM deployments

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="$PROJECT_ROOT/benchmark-results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DURATION=120  # 2 minutes in seconds
APP_URL="http://localhost:5001"

# Ensure bc is available for calculations
if ! command -v bc &> /dev/null; then
    echo "Error: 'bc' calculator is required but not installed."
    echo "Install with: brew install bc (macOS) or apt-get install bc (Ubuntu)"
    exit 1
fi

# Function to display usage
usage() {
    echo "Usage: $0 [docker|vm|compare]"
    echo ""
    echo "Commands:"
    echo "  docker   - Benchmark Docker container deployment"
    echo "  vm       - Benchmark Vagrant VM deployment"
    echo "  compare  - Compare previous Docker and VM benchmark results"
    echo ""
    echo "Examples:"
    echo "  $0 docker    # Test container performance"
    echo "  $0 vm        # Test VM performance"
    echo "  $0 compare   # Show side-by-side comparison"
    exit 1
}

# Function to create results directory
create_results_dir() {
    mkdir -p "$RESULTS_DIR"
    echo "Results will be saved to: $RESULTS_DIR"
}

# Function to get system information
get_system_info() {
    echo "=== System Information ==="
    echo "Timestamp: $(date)"
    echo "Host OS: $(uname -s -r)"
    
    if command -v sw_vers &> /dev/null; then
        # macOS
        echo "macOS Version: $(sw_vers -productVersion)"
        echo "Hardware: $(sysctl -n machdep.cpu.brand_string)"
        echo "Memory: $(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024) "GB"}')"
    elif command -v lsb_release &> /dev/null; then
        # Linux
        echo "Linux Distribution: $(lsb_release -d | cut -f2)"
        echo "CPU: $(lscpu | grep "Model name" | cut -d: -f2 | xargs)"
        echo "Memory: $(free -h | grep "Mem:" | awk '{print $2}')"
    else
        echo "CPU: $(uname -p)"
        echo "Memory: $(free -h 2>/dev/null | grep "Mem:" | awk '{print $2}' || echo "Unknown")"
    fi
    
    echo "Docker Version: $(docker --version 2>/dev/null || echo "Not available")"
    echo "Vagrant Version: $(vagrant --version 2>/dev/null || echo "Not available")"
    echo ""
}

# Function to wait for application readiness
wait_for_app() {
    local max_wait=60
    local counter=0
    
    echo "Waiting for application to be ready at $APP_URL..."
    
    while [ $counter -lt $max_wait ]; do
        if curl -f -s "$APP_URL" > /dev/null 2>&1; then
            echo "Application ready after $counter seconds"
            return 0
        fi
        sleep 1
        counter=$((counter + 1))
    done
    
    echo "Application failed to respond within $max_wait seconds"
    return 1
}

# Function to measure deployment startup time
measure_startup() {
    local platform=$1
    local start_time
    local end_time
    local startup_duration
    
    echo "=== Measuring $platform Startup Time ==="
    
    start_time=$(date +%s.%N)
    
    if [ "$platform" = "docker" ]; then
        echo "Starting Docker deployment..."
        cd "$PROJECT_ROOT"
        if ! ./scripts/docker-deploy.sh > /tmp/docker-deploy.log 2>&1; then
            echo "Docker deployment failed:"
            cat /tmp/docker-deploy.log
            return 1
        fi
    elif [ "$platform" = "vm" ]; then
        echo "Starting VM deployment..."
        cd "$PROJECT_ROOT"
        if ! ./scripts/vagrant-deploy.sh > /tmp/vagrant-deploy.log 2>&1; then
            echo "VM deployment failed:"
            cat /tmp/vagrant-deploy.log
            return 1
        fi
    fi
    
    if wait_for_app; then
        end_time=$(date +%s.%N)
        startup_duration=$(echo "$end_time - $start_time" | bc)
        echo "Total startup time: ${startup_duration} seconds"
        echo "$startup_duration"
        return 0
    else
        echo "Failed to start $platform deployment"
        return 1
    fi
}

# Function to measure resource usage
measure_resources() {
    local platform=$1
    local duration=$2
    local interval=5
    local measurements=0
    local total_cpu=0
    local total_memory=0
    local peak_memory=0
    
    echo "=== Measuring Resource Usage for $duration seconds ==="
    
    for ((i=0; i<duration; i+=interval)); do
        if [ "$platform" = "docker" ]; then
            # Docker resource measurement
            local stats=$(docker stats my-scratch-pad --no-stream --format "table {{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null | tail -n +2)
            if [ -n "$stats" ]; then
                local cpu_pct=$(echo "$stats" | awk '{print $1}' | sed 's/%//')
                local mem_usage=$(echo "$stats" | awk '{print $2}' | sed 's/MiB.*//')
                
                if [[ "$cpu_pct" =~ ^[0-9]*\.?[0-9]+$ ]] && [[ "$mem_usage" =~ ^[0-9]*\.?[0-9]+$ ]]; then
                    total_cpu=$(echo "$total_cpu + $cpu_pct" | bc)
                    total_memory=$(echo "$total_memory + $mem_usage" | bc)
                    
                    if (( $(echo "$mem_usage > $peak_memory" | bc -l) )); then
                        peak_memory=$mem_usage
                    fi
                    
                    measurements=$((measurements + 1))
                fi
            fi
        elif [ "$platform" = "vm" ]; then
            # VM resource measurement
            local vm_stats=$(vagrant ssh -c "free -m | grep '^Mem:' | awk '{print \$3}'; ps aux | awk '{sum += \$3} END {print sum}'" 2>/dev/null)
            if [ -n "$vm_stats" ]; then
                local mem_used=$(echo "$vm_stats" | head -1)
                local cpu_pct=$(echo "$vm_stats" | tail -1)
                
                if [[ "$mem_used" =~ ^[0-9]+$ ]] && [[ "$cpu_pct" =~ ^[0-9]*\.?[0-9]+$ ]]; then
                    total_memory=$(echo "$total_memory + $mem_used" | bc)
                    total_cpu=$(echo "$total_cpu + $cpu_pct" | bc)
                    
                    if (( $(echo "$mem_used > $peak_memory" | bc -l) )); then
                        peak_memory=$mem_used
                    fi
                    
                    measurements=$((measurements + 1))
                fi
            fi
        fi
        
        sleep $interval
    done
    
    if [ $measurements -gt 0 ]; then
        local avg_cpu=$(echo "scale=2; $total_cpu / $measurements" | bc)
        local avg_memory=$(echo "scale=2; $total_memory / $measurements" | bc)
        
        echo "Average CPU Usage: ${avg_cpu}%"
        echo "Average Memory Usage: ${avg_memory}MB"
        echo "Peak Memory Usage: ${peak_memory}MB"
        echo "Measurements taken: $measurements"
        
        echo "${avg_cpu},${avg_memory},${peak_memory},${measurements}"
    else
        echo "No resource measurements collected"
        echo "0,0,0,0"
    fi
}

# Function to measure HTTP performance
measure_http_performance() {
    local duration=$1
    local url=$2
    local temp_file=$(mktemp)
    local successful_requests=0
    local failed_requests=0
    local start_time=$(date +%s)
    local end_time=$((start_time + duration))
    
    echo "=== HTTP Performance Testing for $duration seconds ==="
    echo "Target URL: $url"
    
    # Verify URL is accessible before starting
    if ! curl -f -s "$url" > /dev/null 2>&1; then
        echo "Error: Cannot access $url - application may not be running"
        echo "0,0,1,0,0,0,0,0"
        rm -f "$temp_file"
        return 1
    fi
    
    while [ $(date +%s) -lt $end_time ]; do
        local response_time=$(curl -o /dev/null -s -w "%{time_total}" "$url" 2>/dev/null)
        local exit_code=$?
        
        if [ $exit_code -eq 0 ] && [[ "$response_time" =~ ^[0-9]*\.?[0-9]+$ ]]; then
            successful_requests=$((successful_requests + 1))
            echo "$response_time" >> "$temp_file"
        else
            failed_requests=$((failed_requests + 1))
        fi
        
        sleep 0.1  # Small delay between requests
    done
    
    local total_requests=$((successful_requests + failed_requests))
    
    if [ $successful_requests -gt 0 ]; then
        local requests_per_second=$(echo "scale=2; $successful_requests / $duration" | bc)
        
        # Calculate statistics
        local avg_response=$(awk '{sum+=$1} END {printf "%.4f", sum/NR}' "$temp_file")
        local min_response=$(sort -n "$temp_file" | head -1)
        local max_response=$(sort -n "$temp_file" | tail -1)
        
        # Calculate 95th percentile
        local p95_line=$(echo "scale=0; $successful_requests * 0.95 / 1" | bc)
        if [ "$p95_line" -eq 0 ]; then p95_line=1; fi
        local p95_response=$(sort -n "$temp_file" | sed -n "${p95_line}p")
        
        echo "Total Requests: $total_requests"
        echo "Successful Requests: $successful_requests"
        echo "Failed Requests: $failed_requests"
        echo "Requests per Second: $requests_per_second"
        echo "Average Response Time: ${avg_response}s"
        echo "Min Response Time: ${min_response}s"
        echo "Max Response Time: ${max_response}s"
        echo "95th Percentile: ${p95_response}s"
        
        rm -f "$temp_file"
        echo "$total_requests,$successful_requests,$failed_requests,$requests_per_second,$avg_response,$min_response,$max_response,$p95_response"
    else
        echo "No successful HTTP requests recorded"
        rm -f "$temp_file"
        echo "0,0,$total_requests,0,0,0,0,0"
    fi
}

# Function to benchmark Docker deployment
benchmark_docker() {
    local result_file="$RESULTS_DIR/docker_benchmark_$TIMESTAMP.txt"
    
    echo "=== Docker Benchmark Started ===" | tee "$result_file"
    get_system_info | tee -a "$result_file"
    
    # Clean up any existing containers
    docker stop my-scratch-pad 2>/dev/null || true
    docker rm my-scratch-pad 2>/dev/null || true
    
    # Measure startup time
    echo "Measuring Docker startup performance..." | tee -a "$result_file"
    local startup_time=$(measure_startup "docker")
    if [ $? -ne 0 ]; then
        echo "Docker startup failed" | tee -a "$result_file"
        return 1
    fi
    echo "Startup Time: ${startup_time}s" | tee -a "$result_file"
    echo "" | tee -a "$result_file"
    
    # Measure HTTP performance
    echo "Starting HTTP performance test..." | tee -a "$result_file"
    local http_stats=$(measure_http_performance $DURATION "$APP_URL")
    echo "$http_stats" | tr ',' '\n' | paste -d':' <(echo -e "Total Requests\nSuccessful Requests\nFailed Requests\nRequests per Second\nAverage Response Time\nMin Response Time\nMax Response Time\n95th Percentile") - | tee -a "$result_file"
    echo "" | tee -a "$result_file"
    
    # Measure resource usage during load
    echo "Measuring resource usage during sustained load..." | tee -a "$result_file"
    local resource_stats=$(measure_resources "docker" 30)  # 30 second sample
    echo "$resource_stats" | tr ',' '\n' | paste -d':' <(echo -e "Average CPU Usage (%)\nAverage Memory Usage (MB)\nPeak Memory Usage (MB)\nMeasurements Taken") - | tee -a "$result_file"
    echo "" | tee -a "$result_file"
    
    echo "=== Docker Benchmark Completed ===" | tee -a "$result_file"
    echo "Results saved to: $result_file"
    
    # Clean up
    docker stop my-scratch-pad 2>/dev/null || true
    docker rm my-scratch-pad 2>/dev/null || true
}

# Function to benchmark VM deployment
benchmark_vm() {
    local result_file="$RESULTS_DIR/vm_benchmark_$TIMESTAMP.txt"
    
    echo "=== VM Benchmark Started ===" | tee "$result_file"
    get_system_info | tee -a "$result_file"
    
    # Clean up any existing VM
    cd "$PROJECT_ROOT"
    vagrant destroy -f 2>/dev/null || true
    
    # Measure startup time
    echo "Measuring VM startup performance..." | tee -a "$result_file"
    local startup_time=$(measure_startup "vm")
    if [ $? -ne 0 ]; then
        echo "VM startup failed - aborting benchmark" | tee -a "$result_file"
        return 1
    fi
    echo "Startup Time: ${startup_time}s" | tee -a "$result_file"
    echo "" | tee -a "$result_file"
    
    # Measure HTTP performance
    echo "Starting HTTP performance test..." | tee -a "$result_file"
    local http_stats=$(measure_http_performance $DURATION "$APP_URL")
    if [ $? -ne 0 ]; then
        echo "HTTP performance test failed" | tee -a "$result_file"
        return 1
    fi
    echo "$http_stats" | tr ',' '\n' | paste -d':' <(echo -e "Total Requests\nSuccessful Requests\nFailed Requests\nRequests per Second\nAverage Response Time\nMin Response Time\nMax Response Time\n95th Percentile") - | tee -a "$result_file"
    echo "" | tee -a "$result_file"
    
    # Measure resource usage during load
    echo "Measuring VM resource usage during sustained load..." | tee -a "$result_file"
    local resource_stats=$(measure_resources "vm" 30)  # 30 second sample
    echo "$resource_stats" | tr ',' '\n' | paste -d':' <(echo -e "Average CPU Usage (%)\nAverage Memory Usage (MB)\nPeak Memory Usage (MB)\nMeasurements Taken") - | tee -a "$result_file"
    echo "" | tee -a "$result_file"
    
    echo "=== VM Benchmark Completed ===" | tee -a "$result_file"
    echo "Results saved to: $result_file"
    
    # Clean up
    vagrant halt 2>/dev/null || true
}

# Function to compare benchmark results
compare_results() {
    local docker_result=$(find "$RESULTS_DIR" -name "docker_benchmark_*.txt" | sort | tail -1)
    local vm_result=$(find "$RESULTS_DIR" -name "vm_benchmark_*.txt" | sort | tail -1)
    
    if [ ! -f "$docker_result" ] || [ ! -f "$vm_result" ]; then
        echo "Error: Both Docker and VM benchmark results are required for comparison."
        echo "Run './scripts/benchmark.sh docker' and './scripts/benchmark.sh vm' first."
        return 1
    fi
    
    local comparison_file="$RESULTS_DIR/comparison_$TIMESTAMP.txt"
    
    echo "=== Performance Comparison Report ===" | tee "$comparison_file"
    echo "Generated: $(date)" | tee -a "$comparison_file"
    echo "" | tee -a "$comparison_file"
    
    echo "Docker Results: $(basename "$docker_result")" | tee -a "$comparison_file"
    echo "VM Results: $(basename "$vm_result")" | tee -a "$comparison_file"
    echo "" | tee -a "$comparison_file"
    
    # Extract key metrics for comparison
    local docker_startup=$(grep "Startup Time:" "$docker_result" | awk '{print $3}' | sed 's/s//')
    local vm_startup=$(grep "Startup Time:" "$vm_result" | awk '{print $3}' | sed 's/s//')
    
    local docker_rps=$(grep "Requests per Second:" "$docker_result" | awk '{print $4}')
    local vm_rps=$(grep "Requests per Second:" "$vm_result" | awk '{print $4}')
    
    local docker_avg_response=$(grep "Average Response Time:" "$docker_result" | awk '{print $4}' | sed 's/s//')
    local vm_avg_response=$(grep "Average Response Time:" "$vm_result" | awk '{print $4}' | sed 's/s//')
    
    echo "=== Startup Time Comparison ===" | tee -a "$comparison_file"
    echo "Docker: ${docker_startup}s" | tee -a "$comparison_file"
    echo "VM: ${vm_startup}s" | tee -a "$comparison_file"
    if [ -n "$docker_startup" ] && [ -n "$vm_startup" ]; then
        local startup_ratio=$(echo "scale=1; $vm_startup / $docker_startup" | bc)
        echo "VM is ${startup_ratio}x slower than Docker for startup" | tee -a "$comparison_file"
    fi
    echo "" | tee -a "$comparison_file"
    
    echo "=== HTTP Performance Comparison ===" | tee -a "$comparison_file"
    echo "Docker RPS: $docker_rps" | tee -a "$comparison_file"
    echo "VM RPS: $vm_rps" | tee -a "$comparison_file"
    echo "Docker Avg Response: ${docker_avg_response}s" | tee -a "$comparison_file"
    echo "VM Avg Response: ${vm_avg_response}s" | tee -a "$comparison_file"
    echo "" | tee -a "$comparison_file"
    
    echo "=== Full Docker Results ===" | tee -a "$comparison_file"
    cat "$docker_result" | tee -a "$comparison_file"
    echo "" | tee -a "$comparison_file"
    
    echo "=== Full VM Results ===" | tee -a "$comparison_file"
    cat "$vm_result" | tee -a "$comparison_file"
    
    echo "Comparison report saved to: $comparison_file"
}

# Main script logic
main() {
    if [ $# -eq 0 ]; then
        usage
    fi
    
    create_results_dir
    
    case "$1" in
        docker)
            benchmark_docker
            ;;
        vm)
            benchmark_vm
            ;;
        compare)
            compare_results
            ;;
        *)
            echo "Error: Unknown command '$1'"
            usage
            ;;
    esac
}

# Make scripts executable
chmod +x "$PROJECT_ROOT/scripts/docker-deploy.sh" 2>/dev/null || true
chmod +x "$PROJECT_ROOT/scripts/vagrant-deploy.sh" 2>/dev/null || true

# Run main function
main "$@"