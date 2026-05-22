describe("plot_representative_assessment", {
  it("returns a ggplot object from assessment_detail and assessment_summary", {
    assessment_detail <- readRDS("/workdir/tests/data/assessment_detail.rds")
    assessment_summary <- data.frame(out = 50, est_asym = 0.75)

    result <- plot_representative_assessment(assessment_detail, assessment_summary)

    expect_s3_class(result, "ggplot")
  })
})
