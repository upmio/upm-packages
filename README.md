# upm-packages

The upm packages project is used to provide software image packaging for UPM software, including Dockerfile, configTemplate, pod Template, and configuration parameter parsing files.

## Project Structure

```
<component>/
  <version>/
    image/           # Docker image context
      Dockerfile     # Docker build definition
      serverMGR.sh   # Initialization script
      supervisord.conf # Process supervisor configuration
    charts/          # Helm chart files
      Chart.yaml     # Chart metadata
      values.yaml    # Default configuration values
      templates/     # Kubernetes resource templates
      files/         # Additional configuration files
```

## Usage

[Helm](https://helm.sh) must be installed to use the charts.
Please refer to Helm's [documentation](https://helm.sh/docs/) to get started.

## TL;DR
Once Helm is set up properly, add the repository as follows:

```sh
# Add the repo to helm (typically use a tag rather than main):
helm repo add upm-packages https://upmio.github.io/upm-packages

# list all charts in the repo
helm search repo upm-packages
```

## Installing

The following is the installation method using mysql-community-8.0.41 as an example

```sh
# Update the repo
helm repo update

# Install mysql community 8.0.41 upm package
helm install --namespace=upm-system upm-packages-mysql-community-8.0.41 upm-packages/mysql-community-8.0.41
```

## Uninstalling

You can use Helm to uninstall upm-packages:

```sh
helm uninstall --namespace=upm-system upm-packages-mysql-community-8.0.41 --wait
```

Optionally remove repository from helm:

```sh
helm repo remove upm-packages
```

## Development

### Build Commands
- Build Docker image: `docker buildx build --platform linux/amd64 -t <image-name>:<version> <context-path>`
- Package Helm chart: `helm package <chart-directory>`

### Linting and Testing
- Validate Helm chart: `helm lint <chart-path>`
- Test Helm chart installation: `helm install --dry-run --debug <release-name> <chart-path>`

### CI/CD
- Images are automatically built and pushed to quay.io on changes to `image/` directories
- Helm charts are automatically released on changes to `charts/` directories
