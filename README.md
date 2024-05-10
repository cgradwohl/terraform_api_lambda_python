# CitySense

A public API for connected cities.

![retro_city](iot_city.png)

## Introduction

Hello and thank you for taking the time to review my code. I really enjoyed this project and I am grateful for the oppurtunity to join PlayQ!

## Constraints, Assumptions and Focus

My biggest constraint was time, since I have a full time job and a family. So I treated this project like an mvp or proof of concept, that I could show my team and get buy in for the general technical approach.

I created a prioritized list of tasks that I would like to accomplish next ([see Next Steps](#next-steps)).

With that being said, I decided to focus on four things:

1. core api functionality including basic auth
2. simple infrastructure definitions and setup
3. simple ci/cd workflow
4. unit testing

I did not focus on implementing production-ready requitements or best practices ([see Next Steps](#next-steps)).

## Architecture

![retro_city](city_sense_architecture.png)

## Getting Started

If you would like to run the ci/cd workflow and deploy the infrastructure, then follow these steps.

### prerequisites

Due to time constraints, I decided to use AWS Access to provide permissions to the CI/CD instead of setting up the prefered OpenId provider.

So in a sandbox AWS account, create an AWS IAM Admin and generate access keys for this user. We will use these credentials for our Github workflow.

Set these keys as your default profile on your local machine.

You will also need a Github account.

### 1. Bootstrap the remote backend for terraform

From the root directory run the following bash command in your terminal.

```bash
chmod +x ./bootstrap.sh

./bootstrap.sh
```

Enter the `us-west-1` region.

This script will accomplish two things for you:

- 1. It will deploy an S3 bucket, a DynamoDB table and IAM Policy to manage the state of the application infrastructure.

- 2. It will write the terraform configuration for the application infrastructure in terraform/backend. The Github workflow will then use this configuration to initialize and apply the deployment plans.

### 2. Push the repo to Github

Create a new repo on github. Name it `playq_chris_gradwohl`.

Push this project to the new remote repository:

```bash
git init
git add .
git commit -m "hello!"

git remote add origin git@github.com:<your_github_username>/playq_chris_gradwohl.git
git branch -M main
git push -u origin main
```

### 3. Configure Github Secrets

On first push, the workflow should fail due to missing access keys.

Find the IAM admin user's (from a sandbox account) access key and secret access key and record them as secrets in the github repo.

(From the github repo) Settings > Secrets and variables > Actions

Then click New repository secret button.

Create `AWS_SECRET_ACCESS_KEY` and `AWS_ACCESS_KEY_ID` secrets.

Finally re-run the workflow.

### 4. Invoke the API

Obtain the invoke_url from the `Deploy (App Infra) with Terraform` action of the `Deploy App Infra` job.

Or visit the AWS console to get the `sensor_rest_api` stage url.

## Next Steps {#next-steps}

Here is my thought process to improve the code bath, developer workflows and get ready to go to production.

1. Standardize dependecy management.
   To save time I manually managed all dependecies, but I would like to add more robust and safe dependcy manage tooling like Poetry.
2. Finish unit testing handlers, lib and terraform
   I ran out of time to complete this, but I was able to add a few basic tests.
3. Setup OpenID connect permissions and remove aws access keys.
4. Add handler e2e tests in a test environment
5. Create Terraform modules for Lmabdas, API Gateway and IAM to reduce duplication and improve best practices.
6. Setup multi stage configuration and deployments
7. Setup Lambda versioning, aliasing for rollbacks
8. Add failure destinations for API Gateway, and S3 lambda intratations
9. Setup API metrics and alerting
10. Improve CI/CD to run faster

## Potential Feature's Roadmap

- Pagination Feature
- GET by Longitude and Latitude and proximity
- Configuration Service

## Conclusion

Thank you again for reviewing my work and giving me the oppurtunity!

If you have any questions or concerns please don't hesitate to reach out to me via email: `christophergradwohl@gmail.com`
