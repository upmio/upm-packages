# upm-packages

The upm packages project is used to provide software image packaging for UPM software, including Dockerfile, configTemplate, pod Template, and configuration parameter parsing files.

## Usage

[Helm](https://helm.sh) must be installed to use the charts.
Please refer to Helm's [documentation](https://helm.sh/docs/) to get started.

Once Helm is set up properly, add the repository as follows:

```console
helm repo add upm-packages https://upmio.github.io/upm-packages
```

You can then run `helm search repo upm-packages` to see the charts.

