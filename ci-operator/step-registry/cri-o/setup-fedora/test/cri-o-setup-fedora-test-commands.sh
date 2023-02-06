#!/bin/bash
set -o nounset
set -o errexit
set -o pipefail

# shellcheck source=/dev/null
source "${SHARED_DIR}/env"
chmod +x ${SHARED_DIR}/login_script.sh
${SHARED_DIR}/login_script.sh

instance_name=$(<"${SHARED_DIR}/gcp-instance-ids.txt")

timeout --kill-after 10m 400m gcloud compute ssh --zone="${ZONE}" ${instance_name} -- bash - << EOF 
    REPO_DIR="/home/deadbeef/cri-o"
    cd "\${REPO_DIR}/contrib/test/ci"
    ansible-playbook setup-main.yml --connection=local -vvv
EOF

currentDate=$(date +'%s')
gcloud compute instances stop ${instance_name} --zone=${ZONE} 
gcloud compute images create crio-setup-fedora-${currentDate} --source-disk-zone=${ZONE} --source-disk="${instance_name//[$'\t\r\n']}" --family="crio-setup-fedora"