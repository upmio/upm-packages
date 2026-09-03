# HugeGraph single-node example

The example requires the HugeGraph and HugeGraph Hubble package charts to be
installed into the Unit Operator manager namespace (`upm-system` by default).
The UnitSet controller then copies the versioned ConfigMaps and PodTemplate
from that namespace into `hugegraph-example`.

Install the packages first:

```bash
helm upgrade --install hugegraph-1.3.0 ../charts --namespace upm-system
helm upgrade --install hugegraph-hubble-1.3.0 ../../../hugegraph-hubble/1.3.0/charts --namespace upm-system
```

Create the components in dependency order. Hubble is intentionally in a
separate manifest: it must not be created until HugeGraph is Ready.

```bash
kubectl apply -f 00-hugegraph-project.yaml
kubectl wait --for=create namespace/hugegraph-example --timeout=2m
kubectl --namespace hugegraph-example wait \
  --for=create secret/aes-secret-key --timeout=2m
kubectl apply -f 01-hugegraph-single-unitset.yaml
kubectl wait --namespace hugegraph-example \
  --for=jsonpath='{.status.readyUnits}'=1 unitset/hugegraph --timeout=10m
kubectl apply -f 02-hugegraph-hubble-unitset.yaml
kubectl wait --namespace hugegraph-example \
  --for=jsonpath='{.status.readyUnits}'=1 unitset/hugegraph-hubble --timeout=10m
```

The controller creates `hugegraph-svc` with ports `8080` (REST) and `8182`
(Gremlin). Open Hubble locally with:

```bash
kubectl --namespace hugegraph-example port-forward svc/hugegraph-hubble-svc 8088:8088
```

Then add a graph connection in Hubble with host `hugegraph-svc`, port `8080`,
and graph name `hugegraph`.

`lvm-localpv` is used because it is the storage class in the test cluster.
Change `storageClassName` before applying the manifest in another cluster.
