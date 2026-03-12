# High-Availability-IAC-WebApp

Udagram high-availability web app deployed using **two CloudFormation stacks** (network + app) with an **Application Load Balancer** and an **Auto Scaling Group** in private subnets. Static website content is stored in S3 and synced to the web servers at boot (and refreshed via cron).

## Working URL (evidence)
- WebAppURL: http://udagra-webap-fa9bv82vdifw-947935568.us-east-1.elb.amazonaws.com/

## Diagram
- `Diagram.png`
- `Diagram.svg`

## Deploy / Destroy
From the repo root:

```bash
bash IAC/scripts/deploy.sh
```

When finished (to avoid charges):
```bash
bash IAC/scripts/destroy.sh
```

## Screenshots (evidence folder)
See `screenshots/` for:
- Network stack outputs (CloudFormation `udagram-network`)
- App stack outputs (CloudFormation `udagram-app`)
- Browser showing “It works! Udagram, Udacity”
- S3 bucket objects showing `index.html`

More detailed instructions live in `IAC/README.md`.
