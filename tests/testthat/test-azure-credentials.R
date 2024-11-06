## Test required_credentials() -------------------------------------------------
test_that("az_required_credentials() returns known good values", {
  expect_identical(
    az_required_credentials(),
    c(
      "AZURE_CLIENT_ID",
      "AZURE_TENANT_ID",
      "AZURE_CLIENT_SECRET",
      "AZURE_SUBSCRIPTION_ID",
      "AZURE_RESOURCE_GROUP",
      "AZURE_STORAGE_ACCOUNT"
    )
  )
})

good_cred_list <- list(
  "AZURE_CLIENT_ID" = "aaaa",
  "AZURE_TENANT_ID" = "bananna",
  "AZURE_CLIENT_SECRET" = "xxx-xx", # pragma: allowlist secret
  "AZURE_SUBSCRIPTION_ID" = "10",
  "AZURE_RESOURCE_GROUP" = "blahblah",
  "AZURE_STORAGE_ACCOUNT" = "some-account"
)

## Test fetch_env_credential() -------------------------------------------------
test_that("Credential fetched successfully from env var", {
  withr::with_envvar(c("AZURE_RESOURCE_GROUP" = "abcd"), {
    expect_equal(fetch_env_credential("AZURE_RESOURCE_GROUP"), "abcd")
  })
})

test_that("Missing credential warns", {
  withr::with_envvar(c("AZURE_CLIENT_ID" = ""), {
    expect_warning(fetch_env_credential("AZURE_CLIENT_ID"))
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
    "AZURE_CLIENT_ID" = "aaaa",
    "AZURE_TENANT_ID" = "bananna",
    "AZURE_CLIENT_SECRET" = "xxx-xx", # pragma: allowlist secret
    "AZURE_SUBSCRIPTION_ID" = 10,
    "AZURE_RESOURCE_GROUP" = "blahblah",
    "AZURE_STORAGE_ACCOUNT" = "some-account"
  )
  expect_error(az_validate_credlist(bad_list))
})

test_that("Empty element raises error", {
  bad_list <- list(
    "AZURE_CLIENT_ID" = "aaaa",
    "AZURE_TENANT_ID" = "",
    "AZURE_CLIENT_SECRET" = "xxx-xx", # pragma: allowlist secret
    "AZURE_SUBSCRIPTION_ID" = "10",
    "AZURE_RESOURCE_GROUP" = "blahblah",
    "AZURE_STORAGE_ACCOUNT" = "some-account"
  )
  expect_error(az_validate_credlist(bad_list))
})

test_that("All list elements are length one", {
  bad_list <- list(
    "AZURE_CLIENT_ID" = "aaaa",
    "AZURE_TENANT_ID" = "bananna",
    "AZURE_CLIENT_SECRET" = "xxx-xx", # pragma: allowlist secret
    "AZURE_SUBSCRIPTION_ID" = c("10", 10, TRUE),
    "AZURE_RESOURCE_GROUP" = "blahblah",
    "AZURE_STORAGE_ACCOUNT" = "some-account"
  )
  expect_error(az_validate_credlist(bad_list))
})
