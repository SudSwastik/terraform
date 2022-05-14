# TerraForm 

## Install Terraform

```
$ brew install terraform
```

> Initialize Terraform
```
$ terraform init
```

> Checkout The Changes
```
$ terraform plan -out <name>.tfplan
```

> Apply The Changes
```
$ terraform apply <name>.tfplan
```

> Delete The Resources
```
$ terraform destroy
```

> Set The AWS Credentails based on input Params
```
$ export TF_VAR_aws_access_key=YOUR_ACCESS_KEY
$ export TF_VAR_aws_secret_key=YOUR_SECRET_KEY
```