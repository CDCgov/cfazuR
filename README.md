
<!-- README.md is generated from README.Rmd. Please edit that file -->

# cfazuR

<!-- badges: start -->
<!-- badges: end -->

------------------------------------------------------------------------

:warning: This package is a work in progress. We have not yet written
all functions or released a stable version. Use at your own risk and
consider opening an issue or contributing a PR if you see any problems.

------------------------------------------------------------------------

cfazuR is a toolkit that makes it easy to connect to Azure storage
resources from an R session. It is an opinionated wrapper around
[AzureRMR](https://github.com/Auzre/AzureRMR/tree/master) and
[AzureStor](https://github.com/Auzre/AzureStor/tree/master) that
requires some setup, and adherence cfazuR’s scehma for passing in Azure
credentials.

Once setup is complete, the package makes it possible to access blob
resources using a simple function call, e.g.

``` r
## Read blob into memory
my_data <- az_read_blob(
  container_name = "my_container",
  path = "path/to/blob.csv"
)

## Download blob to local disk
az_download_blob(
  container_name = "my_container",
  path = "path/to/blob.ext",
  dest = "local/destination/blob.ext"
)

## Write to blob storage
az_write_blob(
  my_data,
  container_name = "my_container",
  path = "path/to/blob.ext"
)
```

# Getting started

## Installation

You can install the development version of cfazuR from
[GitHub](https://github.com/) with:

``` r
pak::pak("CDCgov/cfazuR")
```

## Credential setup (required)

To connect to Azure storage resources with cfazuR, you will need to be
able to authenticate (i.e. log in) to Azure from R. You also need to
look up certain Azure credentials (i.e. account information) and store
them in a location that is secure, but accessible to R.

Follow these the steps carefully the first time you set up the package,
and refer back to this page if you ever need to update your credentials.

### 1. Learn how to keep your credentials secure

**Big picture: Treat your credentials like passwords.** Do not commit
them to GitHub, post them on the internet, send them in unencrypted
emails, etc. This is especially important for service principals, which
are essentially passwords. But it’s a good idea to follow these security
guidelines for all of your credentials, the same way you’re probably
already used to doing for other kinds of usernames and account numbers.

**1.1 [Install and activate
detect-secrets](https://potential-adventure-637em36.pages.github.io/docs/pre_commit.html#getting-started-installing-pre-commit)**
as a pre-commit hook. This will check your code for secrets before you
commit to GitHub and raise an error if it detects a problem.

**1.2 Never hard-code your credentials**

``` r
## WHAT NOT TO DO:
az_login(
  tenant = "1234-abcd-0987-zyxw",
  app = "my-actual-client-id",
  password = "my-actual-service-principal" # pragma: allowlist secret
)
```

If you accidentally push this code to GitHub, your secrets are now on
the internet. Instead, write code that represents your credentials as
variables without ever showing the underlying values:

``` r
## DO THIS INSTEAD
##  Load credentials stored in a separate, .json, .yaml, or .toml file
cred_list <- read_json(my_credentials.json)
## or
## Store credentials as environment variables and load them at runtime
cred_list <- cfazuR::get_env_creds() # Load env vars
az_login(
  tenant = cred_list$az_tenant_id,
  app = cred_list$az_client_id,
  password = cred_list$az_service_principal
)
```

### 2. Look up your Azure Credentials

To log in using [client-based authentication]() you will need:

1.  Client ID
2.  Tenant ID
3.  Service principal

To find these, log in to the Azure portal (<https://portal.azure.com/>),
then search for “app registrations” and click on the relevant icon. If
an app registration exists, click on it to reveal a page showing the
associated client ID, and tenant ID. From this page, click again below
“Certificates and secrets” to reveal the service principal value.

\[!NOTE\] If no service principal exists under “App Registrations”,
contact your Azure account administrator to determine if a valid service
principal exists through newer Entra ID services, or if the
administrator can create a new service principal for you.

\[!NOTE\] If you do not have a service principal and are not authorized
to create one, skip \#1-3 and see [authentication methods]() for other
login options.

To verify that your login was valid for the desired storage endpoint
each time you try to connect to resources you will need:

4.  Subscription ID
5.  Resource group
6.  Storage account

To find these, log in to the Azure portal (<https://portal.azure.com/>),
then search for or navigate to “storage accounts”. Click on the storage
account you want to connect to (the name of this account is one
credential you need). Then, click on “overview” at the top of the left
hand blade for this storage account to reveal the Subscription ID and
resource group.

### 3. Store your Azure Credentials for future use

The ultimate goal is to be able to load your credentials as a
`cred_list` object, as demonstrated
[above](#1-learn-how-to-keep-your-credentials-secure). A `cred_list` is
simply a list containing the following named values. Most cfazuR
functions require a `cred_list` input.

- `az_client_id`
- `az_tenant_id`
- `az_service_principal`
- `az_subscription_id`
- `az_resource_group`
- `az_storage_account`

**Option 1: Set your credentials as R environment variables** This is
the recommended option if you are working locally or on the virtual
analyst platform.

To set your credentials as env vars that load with every R session, copy
the text below into your global `~/.Renviron` or your project-level
`repo/.Renviron` file, replacing the right hand side with your Azure
credential values. The values on the RHS must be in quotes.

- Note that if a project-level .Renviron is present, it will prevent the
  global ~/.Renviron from running.

``` r
az_client_id <- "xxxx-xxxx-xxxx-xxxx"
az_tenant_id <- "xxxx-xxxx-xxxx-xxxx"
az_service_principal <- "xxxx-xxxx-xxxx-xxxx"
az_subscription_id <- "xxxx-xxxx-xxxx-xxxx"
az_resource_group <- "my-resource-group"
az_storage_account <- "my-storage-account"
```

You can use `usethis::edit_r_environ()` or
`usethis::edit_r_environ(scope = "project")` to open and edit your
.Renviron files.

You can use `Sys.setenv()` to set temporary env vars that will persist
in your current session.

``` r
Sys.setenv("az_client_id" = "xxxx-xxxx-xxxx-xxxx")

## Check that it worked
Sys.getenv("az_client_id")
```

    > [1] "xxxx-xxxx-xxxx-xxxx"

**Option 2: Save your credentials in a config file** This may be
preferable if you’re running batch jobs or workig in a pipeline that
already uses a config file.

You can save your credentials as a .json, .toml, .yaml or other markup
file, and then use an appropriate reader function to load the file as a
list into R.

``` r
cred_list <- yaml::read_yaml("my_config.yaml")
```

:warning: if you save your credentials in a config file, make sure the
file is in your .gitignore and only transferred using secure protocols.

# Putting it all together

Download a file from Azure blob storage

``` r
# Assuming you have set your credentials as env vars, load them as a list
cred_list <- az_get_env_credentials()

## Read blob into memory
my_data <- az_read_blob(
  container_name = "my_container",
  path = "path/to/blob.csv"
)

## Download blob to local disk
az_download_blob(
  container_name = "my_container",
  path = "path/to/blob.ext",
  dest = "local/destination/blob.ext"
)

## Write to blob storage
az_write_blob(
  my_data,
  container_name = "my_container",
  path = "path/to/blob.ext"
)
```

------------------------------------------------------------------------

## Authentication options

cfazuR uses client-based authentication (i.e. app-based authentication).
This authentication method is designed so that an app (e.g. your R code)
can log in to Azure resources using a service principal (similar to a
token or password), without a human in the loop. Therefore, client-based
authentication will work seamlessly, even if you are trying to run your
code:

- Using a scheduled job
- On a remote machine (e.g. in Azure Batch or on a cluster)
- In any other situation where a human may not be able to respond
  interactivel to a login prompt

In order to set up client-based authentication, you or your Azure
account administrator will need to create a service principal.

If for some reason you are unable to obtain a service principal, you can
still use cfazuR by running
`AzureRMR::az_login(auth_type = "device_code")` at the beginning of each
R session, which will prompt you to log in using your browser. You may
need to tolerate warnings about missing credentials, but downstream
cfazuR functions will work as long as your `az_login` remains valid.

------------------------------------------------------------------------

## Project Admin

- Katelyn Gostic: email = `uep6@cdc.gov`

## General Disclaimer

This repository was created for use by CDC programs to collaborate on
public health related projects in support of the [CDC
mission](https://www.cdc.gov/about/organization/mission.htm). GitHub is
not hosted by the CDC, but is a third party website used by CDC and its
partners to share information and collaborate on software. CDC use of
GitHub does not imply an endorsement of any one particular service,
product, or enterprise.

:information_source: This package and its documentation are being
developed to support in-house workflows at CDC. This code will not
necessarily be designed or maintained for a general audience.

## Public Domain Standard Notice

This repository constitutes a work of the United States Government and
is not subject to domestic copyright protection under 17 USC § 105. This
repository is in the public domain within the United States, and
copyright and related rights in the work worldwide are waived through
the [CC0 1.0 Universal public domain
dedication](https://creativecommons.org/publicdomain/zero/1.0/). All
contributions to this repository will be released under the CC0
dedication. By submitting a pull request you are agreeing to comply with
this waiver of copyright interest.

## License Standard Notice

This repository is licensed under ASL v2 or later.

This source code in this repository is free: you can redistribute it
and/or modify it under the terms of the Apache Software License version
2, or (at your option) any later version.

This source code in this repository is distributed in the hope that it
will be useful, but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
Apache Software License for more details.

You should have received a copy of the Apache Software License along
with this program. If not, see
<http://www.apache.org/licenses/LICENSE-2.0.html>

The source code forked from other open source projects will inherit its
license.

## Privacy Standard Notice

This repository contains only non-sensitive, publicly available data and
information. All material and community participation is covered by the
[Disclaimer](https://github.com/CDCgov/template/blob/master/DISCLAIMER.md)
and [Code of
Conduct](https://github.com/CDCgov/template/blob/master/code-of-conduct.md).
For more information about CDC’s privacy policy, please visit
[http://www.cdc.gov/other/privacy.html](https://www.cdc.gov/other/privacy.html).

## Contributing Standard Notice

Anyone is encouraged to contribute to the repository by
[forking](https://help.github.com/articles/fork-a-repo) and submitting a
pull request. (If you are new to GitHub, you might start with a [basic
tutorial](https://help.github.com/articles/set-up-git).) By contributing
to this project, you grant a world-wide, royalty-free, perpetual,
irrevocable, non-exclusive, transferable license to all users under the
terms of the [Apache Software License
v2](http://www.apache.org/licenses/LICENSE-2.0.html) or later.

All comments, messages, pull requests, and other submissions received
through CDC including this GitHub page may be subject to applicable
federal law, including but not limited to the Federal Records Act, and
may be archived. Learn more at <http://www.cdc.gov/other/privacy.html>.

## Records Management Standard Notice

This repository is not a source of government records but is a copy to
increase collaboration and collaborative potential. All government
records will be published through the [CDC web
site](http://www.cdc.gov).
