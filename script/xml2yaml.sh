#!/bin/bash

write_line() {
    echo "$*" | tee -a virttest_tmp.yaml
}

write_lines() {
    local line=""
    for line; do
        write_line "$line"
    done
}

rm -f virttest_tmp.yaml
write_line "suite: virttest"
write_line "testcase: virttest"
write_line "category: functional"

extra_keys=(VT_GUEST_OS VT_MACHINE_TYPE VT_NO_FILTER VT_ONLY_FILTER ENV_TYPE NO_FILTER ONLY_FILTER VT_QEMU_BIN VT_QEMU_DST_BIN VT_EXTRA_PARAMS)
all_keys=(NAME SUFFIX REFERENCE VT_TYPE)
vt_keys=(SUFFIX VT_GUEST_OS VT_MACHINE_TYPE)
all_keys+=("${extra_keys[@]}")
vt_keys+=("${extra_keys[@]}")
yaml_lines=()
yaml_state=0
test_num=0
while read xml_line; do

    case "$xml_line" in
        *\<TEST_CASE\>*)
            TEST_CASE=start
            for key in "${all_keys[@]}"; do
                eval "$key="
            done
            ;;
        *\<*\>*\</*\>*)
            [ "$TEST_CASE" = "start" ] || continue
            eval "$(echo "$xml_line" | awk -F'<|>' '{print$2}')='$(echo "$xml_line" | awk -F'<|>' '{print$3}')'"
            ;;
        *\</TEST_CASE\>*)
            TEST_CASE=""
            vt_params=""
            for key in "${vt_keys[@]}"; do
                vt_params="$vt_params$(eval echo \$$key)"
            done
            case_lines=("" "virttest-$test_num:" "  vt_reference:" "  - $REFERENCE")
            let test_num++
            for key in "${all_keys[@]}"; do
                case "$key" in
                    REFERENCE) ;;
                    VT_TYPE) case_lines+=("  vt_type: ${VT_TYPE:-libvirt}") ;;
                    NAME) [ "$NAME" != "$REFERENCE" ] && case_lines+=("  vt_name: $NAME") ;;
                    ENV_TYPE) [ -n "$ENV_TYPE" ] && case_lines+=("  vt_env_type: $ENV_TYPE") ;;
                    *) [ -n "$(eval echo \$$key)" ] && case_lines+=("  $(echo "$key" | tr [A-Z] [a-z]): $(eval echo \$$key)") ;;
                esac
            done
            write_lines "${case_lines[@]}"
            ;;
    esac
done <<< "$(xmllint --format "$@")"
