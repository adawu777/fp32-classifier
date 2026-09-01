#!/usr/bin/env bash

set -uo pipefail

# ============================================================
# FP32 Classifier UVM Regression Control Framework
# ============================================================
#
# This script intentionally contains no commercial-simulator command
# lines. Simulator adapters must be validated with an available,
# compatible UVM simulator before they are enabled.
#
# Seed PASS requires all of the following:
#   - simulator exit status == 0
#   - no timeout
#   - completed UVM report summary
#   - UVM_ERROR == 0
#   - UVM_FATAL == 0
#   - no "assertion failed:"
#   - no scoreboard "TEST FAILED"
#   - scoreboard "TEST PASSED" is present
#
# The scoreboard marker alone is never sufficient for PASS.

readonly EXIT_REGRESSION_FAILED=1
readonly EXIT_REGRESSION_UNAVAILABLE=2
readonly EXIT_CONFIGURATION_ERROR=64

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)

readonly MANIFEST_REL="filelists/fp32_uvm.f"
readonly MANIFEST="${REPO_ROOT}/${MANIFEST_REL}"
readonly PRIMARY_TOP="tb_top"

SIMULATOR=${SIMULATOR:-auto}
NUM_SEEDS=${NUM_SEEDS:-20}
FIRST_SEED=${FIRST_SEED:-1}
SEED_TIMEOUT_SECONDS=${SEED_TIMEOUT_SECONDS:-300}
COVERAGE=${COVERAGE:-0}

SELECTED_SIMULATOR=""
SELECTED_EXECUTABLE=""
RESULT_DIR=""
BUILD_DIR=""
SEED_DIR=""
COVERAGE_DIR=""
METADATA_FILE=""
COMPILE_LOG=""
SUMMARY_FILE=""
RESULTS_FILE=""

PASS_COUNT=0
FAIL_COUNT=0
EXECUTED_SEED_COUNT=0

ANALYSIS_STATUS=""
ANALYSIS_REASON=""
ANALYSIS_UVM_ERRORS=""
ANALYSIS_UVM_FATALS=""
ANALYSIS_ASSERTION_FAILURES=0
ANALYSIS_SCOREBOARD_PASS=0
ANALYSIS_SCOREBOARD_FAIL=0


configuration_error() {
    printf 'Configuration error: %s\n' "$1" >&2
    exit "${EXIT_CONFIGURATION_ERROR}"
}


is_positive_integer() {
    [[ $1 =~ ^[1-9][0-9]*$ ]]
}


validate_configuration() {
    [[ -f "${MANIFEST}" ]] ||
        configuration_error "Primary source manifest not found: ${MANIFEST}"

    case "${SIMULATOR}" in
        auto|questa|vcs|xcelium)
            ;;
        *)
            configuration_error \
                "SIMULATOR must be auto, questa, vcs, or xcelium"
            ;;
    esac

    is_positive_integer "${NUM_SEEDS}" ||
        configuration_error "NUM_SEEDS must be a positive integer"

    is_positive_integer "${FIRST_SEED}" ||
        configuration_error "FIRST_SEED must be a positive integer"

    is_positive_integer "${SEED_TIMEOUT_SECONDS}" ||
        configuration_error \
            "SEED_TIMEOUT_SECONDS must be a positive integer"

    [[ "${COVERAGE}" == "0" || "${COVERAGE}" == "1" ]] ||
        configuration_error "COVERAGE must be 0 or 1"
}


canonical_executable() {
    case "$1" in
        questa)  printf '%s\n' "vsim" ;;
        vcs)     printf '%s\n' "vcs" ;;
        xcelium) printf '%s\n' "xrun" ;;
        *)       return 1 ;;
    esac
}


simulator_is_available() {
    local simulator=$1
    local executable

    executable=$(canonical_executable "${simulator}") || return 1
    command -v "${executable}" >/dev/null 2>&1
}


select_simulator() {
    local candidate

    if [[ "${SIMULATOR}" != "auto" ]]; then
        if ! simulator_is_available "${SIMULATOR}"; then
            printf 'Required executable "%s" for SIMULATOR=%s was not found.\n' \
                "$(canonical_executable "${SIMULATOR}")" \
                "${SIMULATOR}" >&2
            return 1
        fi

        SELECTED_SIMULATOR=${SIMULATOR}
        SELECTED_EXECUTABLE=$(command -v \
            "$(canonical_executable "${SIMULATOR}")")
        return 0
    fi

    # Documented auto-detection order: Questa, VCS, then Xcelium.
    for candidate in questa vcs xcelium; do
        if simulator_is_available "${candidate}"; then
            SELECTED_SIMULATOR=${candidate}
            SELECTED_EXECUTABLE=$(command -v \
                "$(canonical_executable "${candidate}")")
            return 0
        fi
    done

    return 1
}


adapter_is_validated() {
    # No commercial-simulator adapter has yet been validated for this
    # repository. Change the selected adapter to return success only
    # after its compile, elaboration, run, UVM, assertion, exit-status,
    # timeout, and optional coverage behavior has been exercised.
    case "$1" in
        questa|vcs|xcelium)
            return 1
            ;;
        *)
            return 1
            ;;
    esac
}


report_unavailable() {
    local detail=$1

    printf 'REGRESSION UNAVAILABLE\n' >&2
    printf '%s\n' "${detail}" >&2
    printf 'Manifest: %s\n' "${MANIFEST_REL}" >&2
    printf 'Primary top: %s\n' "${PRIMARY_TOP}" >&2
    printf 'No seed executions were attempted.\n' >&2
}


initialize_result_layout() {
    local timestamp

    timestamp=$(date -u '+%Y%m%dT%H%M%SZ')
    RESULT_DIR="${REPO_ROOT}/results/regression_${timestamp}/${SELECTED_SIMULATOR}"
    BUILD_DIR="${RESULT_DIR}/build"
    SEED_DIR="${RESULT_DIR}/seeds"
    COVERAGE_DIR="${RESULT_DIR}/coverage"
    METADATA_FILE="${RESULT_DIR}/metadata.txt"
    COMPILE_LOG="${RESULT_DIR}/compile.log"
    SUMMARY_FILE="${RESULT_DIR}/summary.log"
    RESULTS_FILE="${RESULT_DIR}/results.tsv"

    mkdir -p \
        "${BUILD_DIR}" \
        "${SEED_DIR}" \
        "${COVERAGE_DIR}"

    {
        printf 'simulator=%s\n' "${SELECTED_SIMULATOR}"
        printf 'simulator_executable=%s\n' "${SELECTED_EXECUTABLE}"
        printf 'manifest=%s\n' "${MANIFEST_REL}"
        printf 'primary_top=%s\n' "${PRIMARY_TOP}"
        printf 'num_seeds=%s\n' "${NUM_SEEDS}"
        printf 'first_seed=%s\n' "${FIRST_SEED}"
        printf 'seed_timeout_seconds=%s\n' "${SEED_TIMEOUT_SECONDS}"
        printf 'coverage=%s\n' "${COVERAGE}"
        printf 'timestamp_utc=%s\n' "${timestamp}"
    } > "${METADATA_FILE}"

    printf '%s\n' \
        $'seed\tstatus\tsimulator_exit\ttimed_out\tuvm_errors\tuvm_fatals\tassertion_failures\tscoreboard_pass\tscoreboard_fail\tlog' \
        > "${RESULTS_FILE}"

    : > "${SUMMARY_FILE}"
}


compile_primary_snapshot() {
    # Compile/elaborate exactly once from MANIFEST with PRIMARY_TOP.
    # COVERAGE=1 is recognized, but simulator-specific coverage flags
    # and database commands are intentionally not implemented.
    case "${SELECTED_SIMULATOR}" in
        questa)
            printf 'Questa adapter is not implemented or validated.\n' \
                > "${COMPILE_LOG}"
            ;;
        vcs)
            printf 'VCS adapter is not implemented or validated.\n' \
                > "${COMPILE_LOG}"
            ;;
        xcelium)
            printf 'Xcelium adapter is not implemented or validated.\n' \
                > "${COMPILE_LOG}"
            ;;
        *)
            printf 'No selected simulator adapter.\n' > "${COMPILE_LOG}"
            ;;
    esac

    return "${EXIT_REGRESSION_UNAVAILABLE}"
}


run_simulator_seed() {
    local seed=$1

    # This function will eventually invoke the snapshot compiled once by
    # compile_primary_snapshot. The selected adapter must supply the seed
    # using its validated runtime mechanism and select PRIMARY_TOP.
    printf 'Simulator run adapter is not implemented for seed %s.\n' \
        "${seed}" >&2
    return "${EXIT_REGRESSION_UNAVAILABLE}"
}


run_seed_with_timeout() {
    local seed=$1
    local log_file=$2
    local timeout_flag="${BUILD_DIR}/seed_${seed}.timed_out"
    local simulator_pid
    local watchdog_pid
    local simulator_status

    rm -f "${timeout_flag}"

    run_simulator_seed "${seed}" > "${log_file}" 2>&1 &
    simulator_pid=$!

    (
        sleep "${SEED_TIMEOUT_SECONDS}"
        if kill -0 "${simulator_pid}" 2>/dev/null; then
            : > "${timeout_flag}"
            kill -TERM "${simulator_pid}" 2>/dev/null || true
            sleep 5
            kill -KILL "${simulator_pid}" 2>/dev/null || true
        fi
    ) &
    watchdog_pid=$!

    wait "${simulator_pid}"
    simulator_status=$?

    kill "${watchdog_pid}" 2>/dev/null || true
    wait "${watchdog_pid}" 2>/dev/null || true

    if [[ -f "${timeout_flag}" ]]; then
        rm -f "${timeout_flag}"
        printf '%s %s\n' "${simulator_status}" "1"
    else
        printf '%s %s\n' "${simulator_status}" "0"
    fi
}


extract_uvm_count() {
    local severity=$1
    local log_file=$2

    awk -v severity="${severity}" '
        $0 ~ severity "[[:space:]]*:" { value = $NF }
        END {
            if (value != "") {
                print value
            }
        }
    ' "${log_file}"
}


analyze_seed_log() {
    local log_file=$1
    local simulator_status=$2
    local timed_out=$3

    ANALYSIS_STATUS="FAIL"
    ANALYSIS_REASON=""
    ANALYSIS_UVM_ERRORS=$(extract_uvm_count "UVM_ERROR" "${log_file}")
    ANALYSIS_UVM_FATALS=$(extract_uvm_count "UVM_FATAL" "${log_file}")
    ANALYSIS_ASSERTION_FAILURES=0
    ANALYSIS_SCOREBOARD_PASS=0
    ANALYSIS_SCOREBOARD_FAIL=0

    if grep -Eqi 'assertion failed:' "${log_file}"; then
        ANALYSIS_ASSERTION_FAILURES=1
    fi

    if grep -Eq '\[SCOREBOARD\].*TEST PASSED' "${log_file}"; then
        ANALYSIS_SCOREBOARD_PASS=1
    fi

    if grep -Eq '\[SCOREBOARD\].*TEST FAILED' "${log_file}"; then
        ANALYSIS_SCOREBOARD_FAIL=1
    fi

    if [[ "${simulator_status}" -ne 0 ]]; then
        ANALYSIS_REASON="simulator exit status ${simulator_status}"
    elif [[ "${timed_out}" -ne 0 ]]; then
        ANALYSIS_REASON="seed timed out"
    elif ! grep -Eqi 'UVM Report Summary' "${log_file}"; then
        ANALYSIS_REASON="completed UVM report summary not found"
    elif [[ ! "${ANALYSIS_UVM_ERRORS}" =~ ^[0-9]+$ ]]; then
        ANALYSIS_REASON="UVM_ERROR count not found"
    elif [[ ! "${ANALYSIS_UVM_FATALS}" =~ ^[0-9]+$ ]]; then
        ANALYSIS_REASON="UVM_FATAL count not found"
    elif [[ "${ANALYSIS_UVM_ERRORS}" -ne 0 ]]; then
        ANALYSIS_REASON="UVM_ERROR count is ${ANALYSIS_UVM_ERRORS}"
    elif [[ "${ANALYSIS_UVM_FATALS}" -ne 0 ]]; then
        ANALYSIS_REASON="UVM_FATAL count is ${ANALYSIS_UVM_FATALS}"
    elif [[ "${ANALYSIS_ASSERTION_FAILURES}" -ne 0 ]]; then
        ANALYSIS_REASON="assertion failure detected"
    elif [[ "${ANALYSIS_SCOREBOARD_FAIL}" -ne 0 ]]; then
        ANALYSIS_REASON="scoreboard TEST FAILED detected"
    elif [[ "${ANALYSIS_SCOREBOARD_PASS}" -ne 1 ]]; then
        ANALYSIS_REASON="scoreboard TEST PASSED not found"
    else
        ANALYSIS_STATUS="PASS"
        ANALYSIS_REASON="all required PASS conditions satisfied"
    fi
}


append_seed_result() {
    local seed=$1
    local simulator_status=$2
    local timed_out=$3
    local log_file=$4

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "${seed}" \
        "${ANALYSIS_STATUS}" \
        "${simulator_status}" \
        "${timed_out}" \
        "${ANALYSIS_UVM_ERRORS:-missing}" \
        "${ANALYSIS_UVM_FATALS:-missing}" \
        "${ANALYSIS_ASSERTION_FAILURES}" \
        "${ANALYSIS_SCOREBOARD_PASS}" \
        "${ANALYSIS_SCOREBOARD_FAIL}" \
        "${log_file#${RESULT_DIR}/}" \
        >> "${RESULTS_FILE}"

    printf 'Seed %s: %s (%s)\n' \
        "${seed}" "${ANALYSIS_STATUS}" "${ANALYSIS_REASON}" \
        | tee -a "${SUMMARY_FILE}"
}


write_result_summary() {
    {
        printf '\nRegression summary\n'
        printf 'Simulator : %s\n' "${SELECTED_SIMULATOR}"
        printf 'Top       : %s\n' "${PRIMARY_TOP}"
        printf 'Executed  : %s\n' "${EXECUTED_SEED_COUNT}"
        printf 'Passed    : %s\n' "${PASS_COUNT}"
        printf 'Failed    : %s\n' "${FAIL_COUNT}"
    } | tee -a "${SUMMARY_FILE}"
}


run_regression() {
    local offset
    local seed
    local seed_tag
    local log_file
    local run_result
    local simulator_status
    local timed_out

    if ! compile_primary_snapshot; then
        printf 'REGRESSION UNAVAILABLE\n' | tee -a "${SUMMARY_FILE}" >&2
        printf 'Simulator adapter is not implemented or validated.\n' \
            | tee -a "${SUMMARY_FILE}" >&2
        return "${EXIT_REGRESSION_UNAVAILABLE}"
    fi

    # Compile once above; run the resulting snapshot for every seed below.
    for ((offset = 0; offset < NUM_SEEDS; offset++)); do
        seed=$((FIRST_SEED + offset))
        printf -v seed_tag '%06d' "${seed}"
        log_file="${SEED_DIR}/seed_${seed_tag}.log"

        run_result=$(run_seed_with_timeout "${seed}" "${log_file}")
        read -r simulator_status timed_out <<< "${run_result}"
        EXECUTED_SEED_COUNT=$((EXECUTED_SEED_COUNT + 1))

        analyze_seed_log "${log_file}" "${simulator_status}" "${timed_out}"
        append_seed_result \
            "${seed}" "${simulator_status}" "${timed_out}" "${log_file}"

        if [[ "${ANALYSIS_STATUS}" == "PASS" ]]; then
            PASS_COUNT=$((PASS_COUNT + 1))
        else
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    done

    write_result_summary

    if [[ "${EXECUTED_SEED_COUNT}" -eq 0 ]]; then
        printf 'REGRESSION UNAVAILABLE\n' | tee -a "${SUMMARY_FILE}" >&2
        return "${EXIT_REGRESSION_UNAVAILABLE}"
    fi

    if [[ "${FAIL_COUNT}" -ne 0 ||
          "${PASS_COUNT}" -ne "${EXECUTED_SEED_COUNT}" ]]; then
        printf 'REGRESSION FAILED\n' | tee -a "${SUMMARY_FILE}" >&2
        return "${EXIT_REGRESSION_FAILED}"
    fi

    printf 'REGRESSION PASSED\n' | tee -a "${SUMMARY_FILE}"
    return 0
}


main() {
    validate_configuration

    if ! select_simulator; then
        report_unavailable \
            "No supported simulator executable was found for SIMULATOR=${SIMULATOR}."
        exit "${EXIT_REGRESSION_UNAVAILABLE}"
    fi

    printf 'Selected simulator: %s (%s)\n' \
        "${SELECTED_SIMULATOR}" "${SELECTED_EXECUTABLE}"

    if ! adapter_is_validated "${SELECTED_SIMULATOR}"; then
        report_unavailable \
            "The ${SELECTED_SIMULATOR} adapter has not been validated for this repository."
        exit "${EXIT_REGRESSION_UNAVAILABLE}"
    fi

    initialize_result_layout
    run_regression
}


main "$@"
