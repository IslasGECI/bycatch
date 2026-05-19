describe("create_representative_assessment", {
  it("writes CSV and datapackage.json from cached assessment data", {
    cache_path <- "/workdir/tests/test_representative_cache.rds"
    csv_path <- "/workdir/tests/test_representative_assessment.csv"
    dpkg_path <- "/workdir/tests/datapackage.json"
    mock_cache <- list(
      assessment_summary = data.frame(out = 59.3, asym = 70, Rep70 = 0.5, Rep95 = 0.8),
      assessment_detail = data.frame(
        SampleSize = c(1, 2),
        InclusionRate = c(0.11, 0.22),
        iteration = c(1, 2),
        pred = c(0.1, 0.2),
        rep_est = c(37.7, 38.5),
        is_rep = c(FALSE, TRUE)
      )
    )
    saveRDS(mock_cache, cache_path)
    options <- list(
      "rds-path" = cache_path,
      "output-path" = csv_path
    )
    testtools::if_exist_remove(csv_path)
    testtools::if_exist_remove(dpkg_path)
    create_representative_assessment(options)
    expect_true(testtools::exist_output_file(csv_path))
    expect_true(testtools::exist_output_file(dpkg_path))
    testtools::if_exist_remove(csv_path)
    testtools::if_exist_remove(dpkg_path)
    testtools::if_exist_remove(cache_path)
  })
})
