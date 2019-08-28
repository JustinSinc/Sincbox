#!/usr/bin/env bash
# creates or renews letsencrypt certs

# exit if a command fails
set -o errexit

# exit if required variables aren't set
set -o nounset

# return the exit status of the final command before a failure
set -o pipefail

# set logfile location
logfile="$HOME/letsencrypt.log"

# create array of domains
declare -a domains=("domain1" "domain2")

# wrap the script into a function for logging purposes
{

# generate a certificate for each domain
for domain in "${domains[@]}"; do
        sudo certbot-auto certonly --webroot -w /var/www/html --rsa-key-size 2048 -d "$domain" --hsts --uir --agree-tos
done

# end function
} 2>&1 | tee -a "$logfile" >/dev/null
