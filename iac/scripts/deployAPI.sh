# $1 username
# $2 password
# $3 registryUri
# $4 repositoryName
# $5 keyvaultUri
# $6 managedIdentityClientId


curl -fsSL https://get.docker.com -o get-docker.sh 
sudo sh get-docker.sh
docker login --username $1 --password $2 $3 
docker pull $3/$4:latest
docker run -d --restart=always -p 80:80 -e KeyVaultEndpoint=$5 -e ManagedIdentityClientId=$6 $3/$4:latest