# MutatingWebhookConfiguration cacerts-webhook

The webhook calls update-ca-certificates and mounts the result into a shared volume with the main container

Create a key and a certificate with CN cacerts-mutating-webhook.default.svc as observed in the Service yaml.

```
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365   -nodes -subj "/CN=cacerts-mutating-webhook.default.svc"   -addext "subjectAltName=DNS:cacerts-mutating-webhook.default.svc"
```

Then in caBundle in webhook-configuration.yaml add the output of base64 -w0

```base64 -w0 cert.pem > cert.base64```

```
webhooks:
  - name: cacerts-webhook.server.local
    clientConfig:
      service:
        name: cacerts-mutating-webhook
        namespace: default
        path: "/mutate"
        port: 8080
      caBundle: LS0tLS....................................
```
