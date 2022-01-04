#!/bin/bash

declare -A kvs=()

function handle_placeholder() {
    local file=$1
    echo "--- >>> handle local-file-placeholder:$file <<< ---"
    if [ -f $file ]; then
        for key in ${!kvs[@]}; do
            value=${kvs[$key]}
            value=${value//\//\\\/}
            sed -i "s/{{$key}}/${value}/g" $file
            echo "--- k:v<->$key=$value ---"
        done
        return 0
    fi
    if [ -d $file ]; then
        for f in $(ls $file); do
            handle_placeholder "${file}/${f}"
        done
    fi
    return 0
}

echo "====读取CA变量列表===="
while read line; do
    if [ "${line:0:1}" == "#" -o "${line:0:1}" == "" ]; then
        continue
    fi
    key=${line/=*/}
    value=${line#*=}
    echo "$key=$value"
    kvs["$key"]="$value"
done <./openssl_config_default.properties
echo "===================="

echo "====替换CA配置文件===="
for element in $(find . -name "*.conf" -type f); do
    conf_file=$element
    handle_placeholder $conf_file
done
echo "====替换CA执行文件===="
for element in $(find . -name "*.sh" -type f); do
    conf_file=$element
    handle_placeholder $conf_file
done
echo "================="
echo "CA变量替换完成: $(pwd)"
