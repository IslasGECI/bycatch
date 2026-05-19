describe("render potential kba", {
  it("reads GeoPackage artifact and writes PNG figure", {
    gpkg_path <- "/workdir/tests/test_render_kba.gpkg"
    output_path <- "/workdir/tests/kba.png"

    # Build a GeoPackage artifact from the existing fixture
    testtools::if_exist_remove(gpkg_path)
    site <- readRDS("/workdir/tests/data/kba_polygons.rds")
    sf::st_write(site, gpkg_path, quiet = TRUE)

    options <- list(
      "gpkg-path" = gpkg_path,
      "output-path" = output_path
    )
    testtools::if_exist_remove(output_path)
    render_potential_kba(options)
    expect_true(testtools::exist_output_file(output_path))
    testtools::if_exist_remove(output_path)
    testtools::if_exist_remove(gpkg_path)
  })
})
