#!/usr/bin/env bash
    #=
    exec julia --project="$(realpath $(dirname $0))" --color=yes --startup-file=no -e "include(popfirst!(ARGS))" \
    "${BASH_SOURCE[0]}" "$@"
    =#
    
include(joinpath(dirname(dirname(@__FILE__)), "src", "EyeTracking.jl"))

using .EyeTracking
using Test

@testset "EyeTracking.jl" begin
    # Write your tests here.
end
