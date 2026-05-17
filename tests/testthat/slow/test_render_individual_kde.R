describe("render individual kde", {
  it("reads GeoPackage artifact and writes PNG figure", {
    gpkg_path <- "/workdir/tests/test_render_kde.gpkg"
    output_path <- "/workdir/tests/individual_kde.png"

    # Build a GeoPackage artifact from the existing fixture
    testtools::if_exist_remove(gpkg_path)
    ud_polygons <- readRDS("/workdir/tests/data/ud_polygons.rds")
    sf::st_write(ud_polygons, gpkg_path, quiet = TRUE)

    options <- list(
      "gpkg-path" = gpkg_path,
      "output-path" = output_path
    )
    testtools::if_exist_remove(output_path)
    render_individual_kde(options)
    expect_true(testtools::exist_output_file(output_path))
    testtools::if_exist_remove(output_path)
    testtools::if_exist_remove(gpkg_path)
  })
})
