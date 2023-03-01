# Namespaces
Add manifest files to this directory to create developer namespaces in your clusters.

Developer namespaces are namespaces tagged with the annotation `apps.tanzu.vmware.com/tap-ns` and have an empty string value.  These namespaces will automatically be recognized by the [Tanzu Application Platform Namespace Provisioner](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.4/tap/namespace-provisioner-about.html) and will have the resources in the `custom-resources` folder and the `overlays` folder applied to them automatically.  Changes to the contents of the `custom-resources` folder and the `overlays` folder will be applied to existing and new namespaces, automatically.

Example namespace with annotation for the Namespace Provisioner:
```
apiVersion: v1
kind: Namespace
metadata:
  annotations:
    apps.tanzu.vmware.com/tap-ns: ''
  name: cdelashmutt
```