describe("plot_potential_kba", {
  it("returns a ggplot object from an sf polygons object", {
    site <- readRDS("/workdir/tests/data/kba_polygons.rds")

    result <- plot_potential_kba(site)

    expect_s3_class(result, "ggplot")
  })

  it("calls st_make_valid before passing to mapSite to handle invalid geometries", {
    site <- readRDS("/workdir/tests/data/kba_polygons.rds")

    # The fixture has invalid geometries — this proves the test is meaningful
    expect_false(all(sf::st_is_valid(site)))

    original_make_valid <- sf::st_make_valid
    make_valid_called <- FALSE

    local_mocked_bindings(
      st_make_valid = function(x) {
        make_valid_called <<- TRUE
        original_make_valid(x)
      },
      .package = "sf"
    )

    result <- plot_potential_kba(site)

    expect_true(make_valid_called)
    expect_s3_class(result, "ggplot")
  })
})
