#!/bin/bash

RED="\e[91m"
GREEN="\e[92m"
BOLD="\e[1m"
RESET="\e[0m"
BLUE="\e[94m"

fill="                                                                        "

folder="./examples"
interproc="interproc"
flags="-display text -print_box true"
failure=0
nb_test=0

treat_test(){
  file=$1
  log=${file}.log
  nb_total=$(($nb_total + 1))
  echo -ne "\r${fill}\r${BLUE}${BOLD}Treating${RESET} ${file}"
  $interproc $flags $file > $log
  out=$?
  if [[ $out -ne 0 ]]
  then
    failure=$(($failure + 1))
    echo -e "\n  ${BOLD}${RED} Returned ${out}${RESET}"
  fi
}

for file in $(find "${folder}" -iname "*.txt")
do
  treat_test $file
done
if [[ $nb_total == 0 ]]
then
  echo -e "\r${fill}\r${BOLD}${BLUE}No tests available${RESET}"
elif [[ $failure != 0 ]]
then
  echo -e "\r${fill}\r${BOLD}${RED}${failure}/${nb_total} failed${RESET}"
else
  echo -e "\r${fill}\r${BOLD}${GREEN}all ${nb_total} succesfully executed${RESET}"
fi