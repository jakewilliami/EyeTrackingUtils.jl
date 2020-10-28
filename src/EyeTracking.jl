#!/usr/bin/env bash
    #=
    exec julia --project="$(realpath $(dirname $0))" --color=yes --startup-file=no -e "include(popfirst!(ARGS))" \
    "${BASH_SOURCE[0]}" "$@"
    =#

module EyeTracking

export make_clean_data

include(joinpath(dirname(@__FILE__), "prep.jl"))

end # end module
