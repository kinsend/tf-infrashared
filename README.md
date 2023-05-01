This repository contains the Terraform scripts for the Github Action Runners infrastructure.

[![infracost](https://img.shields.io/endpoint?url=https://dashboard.api.infracost.io/shields/json/dce02035-0c10-4942-b771-659bbc2a148a/repos/066d544b-0b1a-4752-9188-5dc8e6760f3f/branch/dac4f59b-6760-4f95-95c0-200ef5486336)](https://dashboard.infracost.io/org/kinsend/repos/066d544b-0b1a-4752-9188-5dc8e6760f3f)
# Pre-requisites

* AWS
  * Sub-accounts
    * `kinsend-dev`
    * `kinsend-prod`
  * Roles
    * `kinsend-infra`
  * An S3 bucket for the state (`kinsend-infra-state`).

* An Infracost registration.
* Github
  * A Github organization.
    * The organization needs to have Github Actions / Workflows enabled.
  * A Github bot account (`ks-devops-bot`).
    * A PAT (Personal Access Token) needs to be created for the bot account with these permissions:
      * `repo` (all)
      * `admin:org` (all) (mandatory for organization-wide runners)
      * `admin:enterprise` (all) (mandatory for enterprise-wide runners)
      * `admin:public_key` - `read:public_key`
      * `admin:repo_hook` - `read:repo_hook`
      * `admin:org_hook`
      * `notifications`
      * `workflow`
    * The bot account needs to be added to the organization as a member of the `ks-bots` Github team.
    * The bot account needs to be an owner of the organization.
    * The bot account's token needs to be added to the AWS Secrets Manager as a secret called `github/ks-devops-bot/tokens/github-action-runners`.
      The ARN for this should be updated in the [kinsend-infra/github-action-runners/_environment-local.tf](./kinsend-infra/github-action-runners/_environment-local.tf) file under the `github_token`.
  * Secrets
    * `KS_DEVOPS_BOT_SSH_KEY`
    * `KS_DEVOPS_BOT_TOKEN`
      * This is the Github token for the `ks-devops-bot` account.
      * It is used to create the Github Action Runners.
      * It is used to post the Infracost report comments.
    * `INFRACOST_API_KEY`
      * This is used to get the cost estimates.
      * It can be obtained from [infracost.io](https://www.infracost.io/).

# AWS Accounts

The following accounts are used:
* `ks-dev` sub-account
  * This is used for the `dev` environment.
* `ks-prod` sub-account
  * This is used for the `prod` environment.

The AWS accounts are defined in `scripts/aws-account-ids`.

The `aws-vault` template settings are defined in `scripts/aws-vault-config`.

## AWS Roles

* Must already exist:
  * `kinsend-infra`
    * This role is used to manage the infrastructure.
    * It has `AdministratorAccess`.
    * It has `AmazonSSMManagedInstanceCore`.
  * `kinsend-dev`
    * This role is used to manage the `kinsend-dev` AWS sub-account.
  * `kinsend-prod`
    * This role is used to manage the `kinsend-prod` AWS sub-account.
* Created during the bootstrap process:
  * `kinsend-ci-admin`
    * This is the role used by the CI/CD pipeline to run the Terraform scripts.
    * It has `AdministratorAccess`.
    * It is used for remote accounts.
    * Each of the sub-accounts should have a role with the same name.
  * `kinsend-github-action-runners-admin`
    * This is the IAM role for the Github Action Runner EC2 instances.

# How To Set Up `aws-vault`

* Download and install [aws-vault](https://github.com/99designs/aws-vault).
* Create an AWS secret + access key pair for your user.
* Create an MFA token for your user with your username as the name of the MFA device
  ([see here](https://console.aws.amazon.com/iam/home?region=us-east-1#/security_credentials)).
* Create an `~/.aws/config` file with the following content:
```bash
[default]
region          = us-east-1

[profile kinsend-iam]
region          = us-east-1
mfa_serial      = arn:aws:iam::202337591493:mfa/<YOUR_ACCOUNT_MFA_ID>

[profile kinsend-infra]
region          = us-east-1
mfa_serial      = arn:aws:iam::202337591493:mfa/<YOUR_ACCOUNT_MFA_ID>
role_arn        = arn:aws:iam::202337591493:role/kinsend-infra
source_profile  = kinsend-iam

[profile kinsend-dev]
region          = us-east-1
mfa_serial      = arn:aws:iam::202337591493:mfa/<YOUR_ACCOUNT_MFA_ID>
role_arn        = arn:aws:iam::874822220446:role/kinsend-dev
source_profile  = kinsend-iam

[profile kinsend-prod]
region          = us-east-1
mfa_serial      = arn:aws:iam::202337591493:mfa/<YOUR_ACCOUNT_MFA_ID>
role_arn        = arn:aws:iam::780602547172:role/kinsend-prod
source_profile  = kinsend-iam
```
* Create a `~/.aws/aws-vault-config` file with the following content:
```bash
[profile kinsend-iam]
region          = us-east-1

[profile kinsend-infra]
region          = us-east-1
role_arn        = arn:aws:iam::202337591493:role/kinsend-infra
source_profile  = kinsend-iam

[profile kinsend-dev]
region          = us-east-1
role_arn        = arn:aws:iam::874822220446:role/kinsend-dev
source_profile  = kinsend-iam

[profile kinsend-prod]
region          = us-east-1
role_arn        = arn:aws:iam::780602547172:role/kinsend-prod
source_profile  = kinsend-iam
```
* Execute:
```bash
$ aws-vault add kinsend-iam
Enter Access Key ID: ******************************
Enter Secret Access Key: **************************
Added credentials to profile "kinsend-iam" in vault
```
* Execute the following command to add your AWS credentials to the `aws-vault`:
```bash
aws-vault login kinsend-infra
```

# Modules

## `base-infra`

This module creates the base infrastructure. It sets up:
* Core IAM roles
* A VPC
* Subnets
* Internet Gateway
* Security groups
* The ECR for the [kinsend/github-action-runners-docker](https://github.com/kinsend/github-action-runners-docker/) repository.

## `github-action-runners`

This module creates the Github Action Runners infrastructure.

There is an Auto Scaling Group (ASG) which will spin up new instances, if any die or their CPU exceeds 60%.
The ASG is currently set to have a minimum of 1 instance, a desired 1 instance and a maximum of 3 instances.

The userdata script can be found under [github-action-runners/templates](./github-action-runners/templates).

### Docker

The Docker images for the Github Action Runners are built from
[kinsend/github-action-runners-docker](https://github.com/kinsend/github-action-runners-docker/).
Updates there are handled via pull requests. Once the pull request has been merged, a tag needs to be created (manually)
based on the `master` and then get pushed to the remote.

In order to upgrade the version of the Docker image used in the `tf-infrashared` repository,
the `kinsend-infra/github-action-runners/templates/start-docker-containers.sh.tpl`
needs to be updated accordingly.

### Supported OS

* Linux
  This is fully functional and tested.
  We're using Amazon Linux 2, which is based on RHEL 7.
  Each EC2 instance runs one Docker container, but more could be added to the userdata script, as and when necessary.

## Applying Changes to Terraform State

The state is stored under the `kinsend-infra-tf-state` S3 bucket.

If executing from your local machine:
```bash
aws-vault exec kinsend-infra -- terraform init
aws-vault exec kinsend-infra -- terraform get
aws-vault exec kinsend-infra -- terraform plan -out tf.plan
aws-vault exec kinsend-infra -- terraform apply tf.plan
```

# How The Pipeline Works

1. A pull request is created against the `master` branch.
2. The pipeline is triggered.
3. The pipeline checks out the code and runs `terraform plan`.
4. If the `plan` is successful and the work is considered complete, someone on the [CODEOWNERS](./CODEOWNERS) list needs to
   approve the pull request.
5. Once the pull request has been approved, a comment with the `/apply` command needs to be posted.
6. The pipeline will run `terraform apply` and apply the changes to the infrastructure.
7. The pull request can then be merged into `master`.

Please, note that once the changes have been applied, the EC2 instances for the Github Action Runners
WILL NOT BE updated automatically.
In order to do that, you need to:
* Manually scale down the number of minimum and desired instances in the ASG to 0 and apply the settings.
* Scale the settings back to their previous values. The new instances that will be created,
  will have the new Docker image.

# Useful Links

* [myoung34/docker-github-actions-runner](https://github.com/myoung34/docker-github-actions-runner)
* [myoung34/docker-github-actions-runner: Usage](https://github.com/myoung34/docker-github-actions-runner/wiki/Usage)
* AWS
  * [Access Policies: Identity vs. Resource](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_identity-vs-resource.html)
  * [Troubleshooting Roles](https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_roles.html)
* [Infracost](https://www.infracost.io/docs/)
