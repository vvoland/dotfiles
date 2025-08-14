function aws-login
  set -e AWS_ACCESS_KEY_ID AWS_CREDENTIAL_EXPIRATION AWS_PROFILE AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
  export AWS_PROFILE=$(aws configure list-profiles | fzf)
  infra-cli aws login -y
  aws configure export-credentials --format env | source $argv
end
