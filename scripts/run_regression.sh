#!/bin/bash

# ============================================================
# FP32 Classifier UVM Multi-Seed Regression
# ============================================================

NUM_SEEDS=20

LOG_DIR="logs"
SUMMARY_FILE="${LOG_DIR}/regression_summary.log"

PASS_COUNT=0
FAIL_COUNT=0

FAILED_SEEDS=()

mkdir -p "${LOG_DIR}"

# Clear previous summary
> "${SUMMARY_FILE}"


echo "========================================"
echo "FP32 Classifier UVM Regression"
echo "Number of seeds: ${NUM_SEEDS}"
echo "========================================"

echo "FP32 Classifier UVM Regression" >> "${SUMMARY_FILE}"
echo "Number of seeds: ${NUM_SEEDS}"  >> "${SUMMARY_FILE}"
echo "========================================" >> "${SUMMARY_FILE}"


for ((seed=1; seed<=NUM_SEEDS; seed++))
do

    echo ""
    echo "----------------------------------------"
    echo "Running seed = ${seed}"
    echo "----------------------------------------"

    LOG_FILE="${LOG_DIR}/seed_${seed}.log"


    # ========================================================
    # Simulator Command
    # ========================================================
    #
    # Replace this section later with your simulator command.
    #
    # Examples:
    #
    # Questa:
    #
    # vsim -c tb_top \
    #      -sv_seed ${seed} \
    #      -do "run -all; quit" \
    #      > "${LOG_FILE}" 2>&1
    #
    #
    # VCS:
    #
    # ./simv \
    #      +ntb_random_seed=${seed} \
    #      > "${LOG_FILE}" 2>&1
    #
    #
    # Xcelium:
    #
    # xrun \
    #      -svseed ${seed} \
    #      ... \
    #      > "${LOG_FILE}" 2>&1
    #
    # ========================================================


    # Temporary placeholder until simulator is available
    echo "Seed = ${seed}" > "${LOG_FILE}"
    echo "Simulation command not configured yet." >> "${LOG_FILE}"


    # ========================================================
    # PASS / FAIL Detection
    # ========================================================
    #
    # Scoreboard prints:
    #
    # TEST PASSED
    #
    # or
    #
    # TEST FAILED
    #
    # ========================================================


    if grep -q "TEST PASSED" "${LOG_FILE}"
    then

        echo "Seed ${seed}: PASS"

        PASS_COUNT=$((PASS_COUNT + 1))

        echo "Seed ${seed}: PASS" >> "${SUMMARY_FILE}"

    else

        echo "Seed ${seed}: FAIL"

        FAIL_COUNT=$((FAIL_COUNT + 1))

        FAILED_SEEDS+=("${seed}")

        echo "Seed ${seed}: FAIL" >> "${SUMMARY_FILE}"

    fi

done


# ============================================================
# Regression Summary
# ============================================================

echo ""
echo "========================================"
echo "Regression Summary"
echo "========================================"

echo "Total Seeds : ${NUM_SEEDS}"
echo "Passed      : ${PASS_COUNT}"
echo "Failed      : ${FAIL_COUNT}"


echo "" >> "${SUMMARY_FILE}"
echo "========================================" >> "${SUMMARY_FILE}"
echo "Regression Summary" >> "${SUMMARY_FILE}"
echo "========================================" >> "${SUMMARY_FILE}"

echo "Total Seeds : ${NUM_SEEDS}" >> "${SUMMARY_FILE}"
echo "Passed      : ${PASS_COUNT}" >> "${SUMMARY_FILE}"
echo "Failed      : ${FAIL_COUNT}" >> "${SUMMARY_FILE}"


# ============================================================
# Print Failed Seeds
# ============================================================

if [ ${FAIL_COUNT} -gt 0 ]
then

    echo ""
    echo "Failed Seeds:"

    echo "" >> "${SUMMARY_FILE}"
    echo "Failed Seeds:" >> "${SUMMARY_FILE}"

    for seed in "${FAILED_SEEDS[@]}"
    do
        echo "  ${seed}"
        echo "  ${seed}" >> "${SUMMARY_FILE}"
    done

fi


# ============================================================
# Final Regression Result
# ============================================================

echo ""

if [ ${FAIL_COUNT} -eq 0 ]
then

    echo "REGRESSION PASSED"

    echo "" >> "${SUMMARY_FILE}"
    echo "REGRESSION PASSED" >> "${SUMMARY_FILE}"

    exit 0

else

    echo "REGRESSION FAILED"

    echo "" >> "${SUMMARY_FILE}"
    echo "REGRESSION FAILED" >> "${SUMMARY_FILE}"

    exit 1

fi