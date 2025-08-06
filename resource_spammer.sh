#!/bin/bash

template_file=""
base_plural="skeletons"
base_kind="Skeleton"
base_name="skelly"
kind_start=0
kind_count=1
resource_start=0
resource_count=1
do_delete_resources=false

while getopts t:p:k:n:S:C:s:c:d opt; do
    case ${opt} in
        t)
            template_file=$OPTARG
            ;;
        p)
            base_plural=$OPTARG
            ;;
        k)
            base_kind=$OPTARG
            ;;
        n)
            base_name=$OPTARG
            ;;
        S)
            kind_start=$OPTARG
            ;;
        C)
            kind_count=$OPTARG
            ;;
        s)
            resource_start=$OPTARG
            ;;
        c)
            resource_count=$OPTARG
            ;;
        d)
            do_delete_resources=true
            ;;
        ?)
            echo "Invalid option: -${OPTARG}"
            exit 1
            ;;
    esac
done

if [ $OPTIND -eq 1 ]; then
    echo "\nUsage:"
    echo "  -t: [Mandatory] Specify template file path whose contents may include the placeholders <PLURAL>, <KIND>, and <NAME>"
    echo "  -p: [Optional] Specify plural base to be appended with number to make multiple; defaults to skeletons"
    echo "  -k: [Optional] Specify kind base to be appended with number to make multiple; defaults to Skeleton"
    echo "  -n: [Optional] Specify name base to be appended with number to make multiple; defaults to skelly"
    echo "  -S: [Optional] Specify first numerical suffix for resource kinds; defaults to 0"
    echo "  -C: [Optional] Specify count of kinds to create; defaults to 1"
    echo "  -s: [Optional] Specify first numerical suffix for name of created resources; defaults to 0"
    echo "  -c: [Optional] Specify count of resources to create; defaults to 1"
    echo "  -d: [Optional] Delete resources instead of creating them"
    echo
fi

if [ -n "$template_file" ]; then
    for ((k=$kind_start; k<$kind_start+$kind_count; k++))
    do
        plural=$base_plural$(printf "%05d" $k)
        kind=$base_kind$(printf "%05d" $k)

        for ((r=$resource_start; r<$resource_start+$resource_count; r++))
        do
            name=$base_name-$(printf "%05d" $r)

            resource_kind=$(sed -e "s/<KIND>/$kind/g" <<< "$(grep "^kind: " $template_file | awk '{print $NF}')")

            if [ $resource_kind == "CustomResourceDefinition" ]; then
                resource_name=$plural.bifrost.mastercard.com
            else
                resource_name=$name
            fi

            if $do_delete_resources; then
                kubectl delete $resource_kind $resource_name --wait=false --ignore-not-found=true
            else
                sed -e "s/<PLURAL>/$plural/g" -e "s/<KIND>/$kind/g" -e "s/<NAME>/$resource_name/g" $template_file | kubectl apply -f -
            fi
        done
    done
fi

# sh resource_spammer.sh -t spammer_templates/crd_template.yaml -S 0 -C 1
# sh resource_spammer.sh -t spammer_templates/skeleton_template.yaml -s 0 -c 1000
# sh resource_spammer.sh -t spammer_templates/dependent_skeleton_template.yaml -s 0 -c 1000
# sh resource_spammer.sh -t spammer_templates/skeleton_template.yaml -S 0 -C 100 -s 0 -c 10