describe("compute_potential_kba", {
  it("returns sf object with potential KBA polygons", {
    sf::sf_use_s2(FALSE)
    kde_data <- readRDS("/workdir/tests/data/kde_20percent_sample.rds")

    result <- compute_potential_kba(
      KDE_surface = kde_data$KDE.Surface,
      represent = 59.30424,
      popSize = 10,
      levelUD = 50
    )

    expect_true(inherits(result, "sf"))
    expect_true(all(c("N_IND", "N_animals", "potentialSite") %in% colnames(result)))
  })
})
