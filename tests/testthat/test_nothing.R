describe("Get version of the module", {
  it("The version is ...", {
    expected_version <- c("0.7.0")
    obtained_version <- packageVersion("bycatch")
    version_are_equal <- expected_version == obtained_version
    expect_true(version_are_equal)
  })
})
