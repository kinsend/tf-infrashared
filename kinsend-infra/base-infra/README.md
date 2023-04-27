This module will need to be executed once manually as follows:

```bash
aws-vault exec kinsend-infra -- terraform init
aws-vault exec kinsend-infra -- terraform get
aws-vault exec kinsend-infra -- terraform plan -out tf.plan
aws-vault exec kinsend-infra -- terraform apply tf.plan
```
