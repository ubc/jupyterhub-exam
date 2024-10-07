### Provision Exam
```bash
saml2aws login
terraform init
terraform apply --var-file EXAM_VAR.tfvars
```

## Clean Up
Once the exam is done, we can clean up the environment with the following command:
```bash
terraform destroy --var-file EXAM_VAR.tfvars
```
