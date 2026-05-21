describe("compute_project_returning_tracks", {
  it("projects returning-trips data to a SpatialPointsDataFrame", {
    returning_trips <- import_trips("/workdir/tests/data/trips_5_ids.csv", filter_returning = TRUE)

    result <- compute_project_returning_tracks(returning_trips)

    expect_true(inherits(result, "SpatialPointsDataFrame"))
  })
})
