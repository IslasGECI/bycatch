describe("render representative assessment", {
  it("reads cache and writes PNG figure", {
    rds_path <- "/workdir/tests/test_render_rep_cache.rds"
    output_path <- "/workdir/tests/representative_assessment.png"

    # Build a cache file from the existing fixture
    assessment_detail <- readRDS("/workdir/tests/data/assessment_detail.rds")
    cache <- list(
      assessment_summary = data.frame(out = 50, est_asym = 0.75),
      assessment_detail = assessment_detail
    )
    saveRDS(cache, rds_path)

    options <- list(
      "rds-path" = rds_path,
      "output-path" = output_path
    )
    testtools::if_exist_remove(output_path)
    render_representative_assessment(options)
    expect_true(testtools::exist_output_file(output_path))
    testtools::if_exist_remove(output_path)
    testtools::if_exist_remove(rds_path)
  })
})
