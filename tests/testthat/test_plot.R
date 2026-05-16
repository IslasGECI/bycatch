describe("plot_representative_assessment", {
  it("returns a ggplot object from assessment_detail data.frame", {
    assessment_detail <- readRDS("/workdir/tests/data/assessment_detail.rds")

    result <- plot_representative_assessment(assessment_detail)

    expect_s3_class(result, "ggplot")
  })
})

describe("plot_potential_kba", {
  it("returns a ggplot object from an sf polygons object", {
    site <- readRDS("/workdir/tests/data/kba_polygons.rds")

    result <- plot_potential_kba(site)

    expect_s3_class(result, "ggplot")
  })
})
