describe("plot_representative_assessment", {
  it("returns a ggplot object from assessment_detail data.frame", {
    assessment_detail <- readRDS("/workdir/tests/data/assessment_detail.rds")

    result <- plot_representative_assessment(assessment_detail)

    expect_s3_class(result, "ggplot")
  })
})
