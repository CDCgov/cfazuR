## Functions to connect to azure storage resources
##
## Several steps needs to happen in order to connect to an azure blob
## endpoint.
## This script defines a lightweight wrapper around AzureRMR
## for each step, then chains the steps together. Because each function in the
## heierarchy includes validation, the code will stop and throw an informative
## error if any step in the sequence fails.
##
## The steps are:
## 0.1 Set credentials as env vars
## 0.2 Get credentials as list from env or pass as a list
## 1. Validate credentials
## 2. Create az_login object and validate
## 3. Get subscription id from az_login and validate
## 4. Get resource group from subscription and validate
## 5. Get storage account from resource gorup and validate
## 6. Get access key from storage account and validate
## 7. Get azure endpoint (using access key) and validate
## 8. Get azure container object (using endpoint) and validate
## Only {0, 2, 7, 8} are exported



## 0. Set and get crednetials from env  ----------------------------------

#' List names of all required azure credentials
#' @returns a character vector containing all required credentials
#'
#' @details used to view required credentials and internally to ensure the set
#' of required credentials is consistent in downstream functions
#' @export
az_required_credentials <- function() {
  c(
    "az_client_id",
    "az_tenant_id",
    "az_service_principal",
    "az_subscription_id",
    "az_resource_group",
    "az_storage_account"
  )
}

#' Internal function: fetch one Azure credential from environment variable
#' and throw an informative error if credential is not found
#'
#' @param env_var A character vector, the credential(s) to fetch
#'
#' @return The value stored as the environment variable "env_var" if it exists
fetch_env_credential <- function(env_var) {
  if (any(!(env_var %in% az_required_credentials()))) {
    invalid_creds <- env_var[!(env_var %in% az_required_credentials())]
    cli::cli_abort(
      c(
        "!" = "{.envvar {invalid_creds}} is not a valid credential name."
      ),
      class = "cfazuR"
    )
  }

  cli::cli_alert_info(
    "Attempting to load credentials {.envvar {env_var}} from env vars."
  )
  credentials <- Sys.getenv(env_var)

  if (any(credentials == "")) {
    missing_creds <- env_var[credentials == ""]
    cli::cli_warn(
      c(
        "!" = "Environment variable {.envvar {missing_creds}} not
        specified or empty",
        "i" = "See {.fn crazuR::az_set_env_credentials} for help setting
        credentials"
      ),
      class = "cfazuR"
    )
  }

  return(credentials)
}

#' Fetch Azure credentials stored as environmental variables, if they exist
#'
#' @returns A list containing all required credentials: "az_tenant_id",
#' "az_subscription", "az_resource_group", "az_storage_account", and "az_service
#' principal", or an informative error if any are missing
#'
#'
#' @details See [Required credential setup](https://github.com/CDCgov/cfazuR/tree/main?tab=readme-ov-file#required-setup-after-installation) #nolint
#' for help finding and specifying Azure credntials.
#' @export
az_get_env_credentials <- function() {
  fetch_env_credential(az_required_credentials()) |> as.list()
}


## 1. Validate credentials -----------------------------------------------------

#' Checks that a list of credentials contains all expected credentials
#'
#' @param cred_list a named list of credentials. Names must match the set of
#' required credentials returned by [az_required_credentials()]. All values must
#' be non-empty strings.
#'
#' @details Checks that credentials exist, but does not connect to Azure to
#' check that the credentials are valid
#' @export
az_validate_credlist <- function(cred_list) {
  ## Check that is list
  if (!is.list(cred_list)) {
    cli::cli_abort("!" = "Input `cred_list` must be a list.")
  }
  ## Check that list names include all required credentials
  cred_in_list <- (az_required_credentials() %in% names(cred_list))
  names(cred_in_list) <- az_required_credentials()
  missing_creds <- az_required_credentials()[!cred_in_list]
  if (!all(cred_in_list)) {
    cli::cli_abort(
      c(
        "!" = "cred_list must include:{.field {az_required_credentials()}}",
        "i" = "{.field {missing_creds}} are missing from {.field cred_list}"
      )
    )
  }
  element_length <- sapply(cred_list, length)
  bad_inputs <- cred_list[element_length > 1]
  if (!all(element_length == 1)) {
    cli::cli_abort(
      c(
        "!" = "Each credential value must be a single nonempty string.",
        "i" = "You input these values with length > 1:
        {.field {names(bad_inputs)}} with values {.field {bad_inputs}}."
      )
    )
  }
  is_nonempty_character <- lapply(cred_list, function(x) {
    is.character(x) & (x != "")
  }) |> unlist()
  bad_inputs <- cred_list[!is_nonempty_character]
  if (!all(is_nonempty_character)) {
    cli::cli_abort(
      c(
        "!" = "Each credential value must be a single nonempty string.",
        "i" = "You input these bad credentials: {.field {names(bad_inputs)}}
        with values {.field {bad_inputs}}."
      )
    )
  }
}
