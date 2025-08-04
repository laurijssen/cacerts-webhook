# Install MutatingWebhook

The service is accessed over https by he kube-apiserver so we need to generate certificates.

First generate a private key:

```
openssl genrsa -out webhook.key 2048
```

Then generate a certificate signing request with openssl.

subj must be service name plus namespace "/CN=cacerts-mutating-webhook.default.svc"

```
openssl req -new -key webhook.key -out webhook.csr -subj "/CN=cacerts-mutating-webhook.default.svc" 
```

Then do a self signing. Days 3650 means 10 years valid.

```
openssl x509 -req -in webhook.csr -signkey webhook.key -out webhook.crt -days 3650
```

# Create key csr cert with CN/SAN one liner

Best to do it with one liner, include SAN's and Common Name at once

```
openssl req -x509 -nodes -days 3650 -newkey rsa:2048   -keyout webhook.key -out webhook.crt   -subj "/CN=cacerts-mutating-webhook.default.svc"   -addext "subjectAltName=DNS:cacerts-mutating-webhook.default.svc,DNS:cacerts-webhook.server.local"
```

Now we have a certificate that we can put in the caBundle field in webhook-configuration.yaml

```
cat webhook.crt | base64 | tr -d '\n'
```

caBundle: LS01...........

# build the container

There is a Dockerfile in the repo, so just build and push as usual.

```
docker buildx build -t <your-repo>/cacertshook:1.0.0 . --push
```

## secret for the service

Create a secret for the webhook to call over https

```
kubectl create secret tls cert-webhook --key=./webhook.key --cert=./webhook.crt
```

## create Deployment

Create the deployment with service for the webhook container. See webhook-deployment.yaml

Most important fields are the image providing the code and volume cert-webhook that injects the key and certificate into the container

```
      image: <your-repo>/cacertshook:1.0.0

      volumes:
        - name: cert
          secret:
            secretName: cert-webhook
```

```
kubectl apply -f webhook-deployment.yaml
```

## create MutatingWebhookConfiguration

See webhook-configuration-developer.yaml

Most important field is clientConfig where name points to the cacerts-mutating-webhook service created with the Deployment

```
        name: cacerts-mutating-webhook
        namespace: default
        path: "/mutate"
        port: 8080
      caBundle: LS0t..........
```

```
kubectl apply -f webhook-configuration.yaml
```
