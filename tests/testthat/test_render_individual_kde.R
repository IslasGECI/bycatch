describe("render individual kde", {
  it("reads RDS artifact and writes PNG figure", {
    rds_path <- "/workdir/tests/test_render_kde.rds"
    output_path <- "/workdir/tests/individual_kde.png"

    # Build an RDS artifact from the existing fixture
    testtools::if_exist_remove(rds_path)
    ud_polygons <- readRDS("/workdir/tests/data/ud_polygons.rds")
    saveRDS(list(UDPolygons = ud_polygons), rds_path)

    options <- list(
      "rds-path" = rds_path,
      "output-path" = output_path
    )
    testtools::if_exist_remove(output_path)
    render_individual_kde(options)
    expect_true(testtools::exist_output_file(output_path))
    testtools::if_exist_remove(output_path)
    testtools::if_exist_remove(rds_path)
  })
})
