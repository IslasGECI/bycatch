describe("plot_individual_kde", {
  it("returns a ggplot object from UDPolygons", {
    ud_polygons <- readRDS("/workdir/tests/data/ud_polygons.rds")

    result <- plot_individual_kde(ud_polygons)

    expect_s3_class(result, "ggplot")
  })
})
