\# Azure Windows Golden Image



\## Folders

\- `01-setup`: Script to configure RG, Key Vault, App Registration

\- `02-secrets`: Script to fetch secrets from Key Vault

\- `03-packer`: Build golden image with required tools

\- `04-terraform`: Deploy VM from golden image



\## Steps

1\. Run `setup.sh` to configure environment

2\. Run `get-secrets.sh` to load secrets

3\. Run `packer build` to build image

4\. Run `terraform apply` to deploy VM



