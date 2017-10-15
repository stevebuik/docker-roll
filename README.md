# Docker image for Juxt/Roll deployments

Includes the following CLI tools

* Lumo
* Mach
* Lein
* Boot
* AWS CLI
* Terraform

## Deploying using this image

The initial use of this image was in Bitbucket pipelines but it can be used in any Docker environment.

**AWS Profiles**

Roll uses the *default* profile when invoking the *aws* CLI.
This means that you must have a *default* profile present but this can be difficult in Docker instances because the file-system is fresh each time.
One solution is to invoke `aws configure` for the 3 required environment variables in the build steps:

`aws --profile default configure set region $AWS_REGION`

`aws --profile default configure set aws_access_key_id $AWS_ACCESS_KEY_ID`

`aws --profile default configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY`

**Terraform State**

Terraform needs a way to store its plans between invocations.
In a CI environment, this state cannot be stored locally.
This is fixed by using a [*remote backend*](https://www.terraform.io/docs/backends/index.html) for Terraform.
There are many backend types but AWS S3 is best suited for a Roll deployment.
This can be added by a function in the Mach *produce* thread-first macro:

<pre><code>
produce (-> config
            (roll.core/preprocess)
            (roll.core/deployment->tf)
            (assoc-in [:terraform :backend "s3"] {:bucket "some-bucket-name"
                                                  :key    "some/key"
                                                  :region "some-aws-region"})
            (roll.core/->tf-json))
</code></pre>

**Terraform Commands**

You must run [terraform init](https://www.terraform.io/docs/commands/init.html) before `terraform plan` so that the providers and backends are correctly prepared.
In other words, the commands for an automated roll deploy using this image are:

`mach upload`

`mach tfjson`

`terraform init`

`terraform plan`

`terraform apply`