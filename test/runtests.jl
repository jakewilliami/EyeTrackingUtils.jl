#!/usr/bin/env bash
    #=
    exec julia --project="$(realpath $(dirname $0))" --color=yes --startup-file=no -e "include(popfirst!(ARGS))" \
    "${BASH_SOURCE[0]}" "$@"
    =#
    
include(joinpath(dirname(@__DIR__), "src", "EyeTrackingUtils.jl"))

using .EyeTrackingUtils
using Test
using CSV, DataFrames # CSV is currently a test-specific dependency

const data_file = joinpath(dirname(@__DIR__), "data", "word_recognition.csv")

@time @testset "EyeTracking.jl" begin
    word_recognition = DataFrame(CSV.File(data_file))
    # https://github.com/jwdink/eyetrackingR/blob/master/tests/testthat/test_analyze_time_bins.R#L29-L35
    data = make_clean_data(
        word_recognition,
        participant_column = :ParticipantName,
        trial_column = :Trial,
        time_column = :TimeFromTrialOnset,
        trackloss_column = :TrackLoss,
        aoi_columns = [:Animate, :Inanimate],
        treat_non_aoi_looks_as_missing = true,
        item_columns = nothing
        )
    @test true
end
