
SSH="ssh -i $3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
#rsync -avh --progress --sparse -e "${SSH}" $1 $2
rsync -a --sparse -e "${SSH}" $1 $2

