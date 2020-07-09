#!/bin/bash

case "$1" in
    -h | --help | ?)
        echo "Usage: $0 [PACKAGE]"
        echo "Count all cls in the git log of Go"
        echo ""
        echo "With no PACKAGE, Count all cls in the current dir."
        echo ""
        echo "  -h, --help     display this help and exit"
        exit 0
    ;;
esac

package_dir=$1
if [[ "${package_dir}" == "" ]] || [[ ! -d "${package_dir}" ]]; then
    package_dir="."
fi

output="go_all_cls.csv"

pkg_arr=( )
sub_arr=( )
count_arr=( )

IFS=$'\n'
cd ${package_dir}
echo "Number,Project,Module,Submodule,Subject,Owner,Owner Email},Submitter,Submitter Email,Commit,Commit Date,Change Url" > ${output}
progress=0
num=0
commit=""
project="go"
module=""
submodule=""
subject=""
owner=""
owner_email=""
submitter=""
submitter_email=""
commit_date=""
change_url=""
#for line in `git log | awk '$1=$1'`; do
for line in `cat test.log| awk '$1=$1'`; do
    case ${progress} in
        0)
            if [[ ${line:0:7} == "commit " ]]; then
                progress=1
                num=`expr ${num} + 1`
                commit=${line:8}
            fi
        ;;
        1)
            if [[ ${line:0:8} == "Author: " ]]; then
                progress=2
                owner_line=${line:8}
                owner=${owner_line%% <*}
                star=`expr ${#owner} + 2`
                len=`expr ${#owner_line} - ${#owner} - 3`
                owner_email=${owner_line:${star}:${len}}
            fi
        ;;
        2)
            if [[ ${line:0:6} == "Date: " ]]; then
                progress=3
                commit_date=${line:6}
            fi
        ;;
        3)
            module=${line%%:*}
            if [[ "${module}" != "" ]]; then
                progress=4
                subject=${line}
                submodule=${module#*/}
                if [[ "${submodule}" == "${module}" ]]; then
                    submodule=""
                else
                    module=${module%%/*}
                fi
                module=${module%%,*}
                submodule=${submodule%%,*}
            fi
        ;;
        4)
            if [[ ${line:0:13} == "Reviewed-on: " ]]; then
                progress=5
                change_url=${line:13}
            fi
        ;;
        5)
            if [[ ${line:0:12} == "Run-TryBot: " ]]; then
                progress=0
                submitter_line=${line:12}
                submitter=${submitter_line%% <*}
                sstar=`expr ${#submitter} + 2`
                slen=`expr ${#submitter_line} - ${#submitter} - 3`
                submitter_email=${submitter_line:${sstar}:${slen}}

                echo "${num},${project},${module},${submodule},${subject},${owner},${owner_email},${submitter},${submitter_email},${commit},${commit_date},${change_url}" >> ${output}
            fi
        ;;
    esac
done