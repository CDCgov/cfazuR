## Test required_credentials() -------------------------------------------------
test_that("az_required_credentials() returns known good values", {
  expect_identical(
    az_required_credentials(),
    c(
      "az_client_id",
      "az_tenant_id",
      "az_service_principal",
      "az_subscription_id",
      "az_resource_group",
      "az_storage_account"
    )
  )
})

good_cred_list <- list(
  "az_client_id" = "aaaa",
  "az_tenant_id" = "bananna",
  "az_service_principal" = "xxx-xx",
  "az_subscription_id" = "10",
  "az_resource_group" = "blahblah",
  "az_storage_account" = "some-account"
)

## Test fetch_env_credential() -------------------------------------------------
test_that("Credential fetched successfully from env var", {
  withr::with_envvar(c("az_resource_group" = "abcd"), {
    expect_equal(fetch_env_credential("az_resource_group"), "abcd")
  })
})

test_that("Missing credential warns", {
  withr::with_envvar(c("az_client_id" = ""), {
    expect_warning(fetch_env_credential("az_client_id"))
  })
})

test_that("Invalid credential fails", {
  expect_error(fetch_env_credential("NOT_A_REAL_KEY"))
})

## Test_az_get_env_credentials

## Test az_validate_credlist() -------------------------------------------------
test_that("List of non-empty strings with expected names passes", {
  expect_silent(
    az_validate_credlist(good_cred_list)
  )
})

test_that("Non-character element raises error", {
  bad_list <- list(
    "az_client_id" = "aaaa",
    "az_tenant_id" = "bananna",
    "az_subscription" = 10,
    "az_resource_group" = "blahblah",
    "az_storage_account" = "some-account",
    "az_service_principal" = "xxx-xx"
  )
  expect_error(az_validate_credlist(bad_list))
})

test_that("Empty element raises error", {
  bad_list <- list(
    "az_client_id" = "aaaa",
    "az_tenant_id" = "bananna",
    "az_subscription" = "",
    "az_resource_group" = "blahblah",
    "az_storage_account" = "some-account",
    "az_service_principal" = "xxx-xx"
  )
  expect_error(az_validate_credlist(bad_list))
})

test_that("All list elements are length one", {
  bad_list <- list(
    "az_client_id" = "aaaa",
    "az_tenant_id" = c("bananna", "apple"),
    "az_subscription" = c("10", 10, TRUE),
    "az_resource_group" = "blahblah",
    "az_storage_account" = "some-account",
    "az_service_principal" = "xxx-xx"
  )
  expect_error(az_validate_credlist(bad_list))
})
