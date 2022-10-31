#!/usr/bin/env bash

yarn clean

## Compile Contracts ##
yarn compile

## Copy Contract Artifacts
mkdir -p build/contracts
cp generated/artifacts/contracts/**/*.json build/contracts
rm build/contracts/*.dbg.json

## Generate Contract Typings ##
cp -r generated/typechain build/typechain

## Export Contract Deployments ##
hardhat_dir=build/hardhat
contracts_export_file=$hardhat_dir/contracts.json
mkdir -p $hardhat_dir
echo '{}' > $contracts_export_file
yarn hardhat export --export-all $contracts_export_file
json=$(cat $contracts_export_file)
echo "$json" | jq '. |= del(."31337")' | jq '. |= with_entries({ key: .key, value: .value | to_entries | .[].value })' > $contracts_export_file
