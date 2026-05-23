describe("plot_potential_kba", {
  it("returns a ggplot object from an sf polygons object", {
    site <- readRDS("/workdir/tests/data/kba_polygons.rds")

    result <- plot_potential_kba(site)

    expect_s3_class(result, "ggplot")
  })
})
