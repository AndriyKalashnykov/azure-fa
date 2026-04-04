# CLAUDE.md

Azure Functions v4 Node.js app with Terraform infrastructure-as-code.

## Build

```bash
make deps       # install Node.js dependencies (pnpm install)
make build      # build the project (runs deps first)
make run        # run locally (runs build first)
make clean      # remove node_modules/ and dist/
make upgrade    # upgrade pnpm dependencies
make release    # create and push a new git tag
make version    # print current version tag
```

## Azure Targets

```bash
make create-resources                  # create Azure resource group and storage account
make create-function                   # create Azure Function App
make publish-function                  # publish function to Azure
make delete-resources                  # delete Azure resources
make tf-create-remote-storage-account  # configure Terraform remote state storage
make aztf-export                       # export Azure Resource Group via aztfexport
```

## Skills

- Makefile -> /makefile
- README.md -> /readme
- renovate.json -> /renovate

## Improvement Backlog

- [ ] Create CI workflow
- [ ] Add LICENSE
