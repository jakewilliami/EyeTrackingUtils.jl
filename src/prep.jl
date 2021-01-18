#!/usr/bin/env bash
    #=
    exec julia --project="$(realpath $(dirname $0))" --color=yes --startup-file=no -e "include(popfirst!(ARGS))" \
    "${BASH_SOURCE[0]}" "$@"
    =#
    
using DataFrames
using Query
using FGenerators

using Lazy: @> # or using DataConvenience: @>, but Lazy exports groupby
using DataFramesMeta: @where
using Statistics: mean
using Unicode:normalize

const _AbstractColumnName = Union{AbstractString, Signed, Symbol, Unsigned}

### R-like function names
# Returns true for true, false, 1, and 0.  Otherwise returns false
_isbool(x) = try Bool(x) catch e false end
# Returns true for a given column in a dataframe if that column is categorical data
_iscategorical(df::DataFrame, col::Symbol) = isa(df[col], CategoricalVector)
_iscategorical(V::AbstractVector) = isa(V, CategoricalVector)
# Similar to as.factor
_ascategorical!(df::DataFrame, col::Symbol) = categorical!(df, col)
DataFrames.categorical!(V::AbstractVector) = CategoricalVector(eltype(V)[v for v in V])
_ascategorical!(V::AbstractVector) = categorical!(V)
# Returns true if the input is boolean
_islogical(x::Union{Bool, Missing}) = true
function _islogical(s::AbstractString)
    s′ = normalize(s, casefold = true)
    if s′ ∈ ("true", "false", "na", "n/a", "missing") # sometimes better than `uppercase` or `lowercase` as it handles unicode characters
        return true
    else
        return false
    end
end
_islogical(x) = false
_islogical(X::AbstractArray) = all(_islogical.(X))
# Returns false for 0 and false.  Otherwise returns true
_aslogical(x::Bool) = Bool(x)
_aslogical(x::Number) = iszero(x) ? false : true
_aslogical(X::AbstractArray) = _aslogical.(X)
function _aslogical(s::AbstractString)
    s′ = normalize(s, casefold = true) # sometimes better than `uppercase` or `lowercase` as it handles unicode characters
    if s′ == "true"
        return true
    elseif s′ == "false"
        return false
    elseif s′ ∈ ("na", "n/a", "missing")
        return missing
    else
        # return nothing
        return missing
    end
end
_aslogical!(df::DataFrame, col::Symbol) = (df[col] = _aslogical(df[col]))
# Returns true for a numerical value
_isnumeric(x::Number) = true
_isnumeric(x) = false
_isnumeric(X::AbstractArray) = all(_isnumeric.(X))
_isnumeric(df::DataFrame, col::Symbol) = _isnumeric(df[col])
# Attempts to parse input as a numeric value
_asnumeric(x::Number) =
_asnumeric(x::Bool) = x ? 1 : 0
_asnumeric(X::AbstractArray) = _asnumeric.(X)
_asnumeric!(df::DataFrame, col::Symbol) = (df[col] = _asnumeric(df[col]))
# equivalent behaviour to `is.na`
Base.ismissing(x::Nothing) = nothing
Base.ismissing(X::AbstractArray) = ismissing.(X)
# equivalent behaviour to `is.null`
Base.isnothing(X::AbstractArray) = all(isnothing.(X))
### Functions defined in eyetrackingR
function _islogical2(x)
    if _islogical(x)
        return true
    elseif _isnumeric(x)
        return false
    else
        throw(error("""
            One of your columns could not be converted
            to the correct format (Bool).  Please do so manually.
        """))
    end
end

# a function from eyetrackingR, but do we need it?
# _asnumeric2(x::T) where T = _asnumeric(parse(T, string(x)))
# _asnumeric2(X::AbstractArray) = _asnumeric2.(X)

# `_check_then_convert` function which takes in a dataframe.
# The `check_function` and `convert_function` necessarily
# uses the dataframe as a parameter
function _check_then_convert(
    df::DataFrame,
    x,
    check_function::Function,
    convert_function::Function,
    colname::Union{String, Symbol};
    verbose::Bool = true
    )
    x′ = Symbol(x)
    if ! check_function(df, x′)
        verbose && println("Converting $(colname) to proper type...")
        x = convert_function(df, x′)
        verbose && println("...done")
    end

    if colname == "Trackloss" && any(ismissing(x))
        @warn "Found NAs in trackloss column.  These will be treated as TRACKLOSS = false."
        x = ismissing(x) ? false : x
    end
    
    return x
end

function _check_then_convert(
    x,
    check_function::Function,
    convert_function::Function,
    colname::Union{String, Symbol};
    verbose::Bool = true
    )
    
    if ! check_function(x)
        verbose && println("Converting $(colname) to proper type...")
        x = convert_function(x)
        verbose && println("...done")
    end
    
    if colname == "Trackloss" && any(ismissing(x))
        @warn "Found NAs in trackloss column.  These will be treated as TRACKLOSS = false."
        x = ismissing(x) ? false : x
    end
    
    return x
end

### Helper functions
@fgenerator function deepvalues(itr::Union{AbstractArray, AbstractDict, Tuple, NamedTuple})
    for v ∈ values(itr)
        @yieldfrom deepvalues(v)
    end
end
@fgenerator deepvalues(x) = @yield x
# Try to return named tuples or pairs!
@fgenerator function deepkeyvalues(d::AbstractDict)
    for (k, v) ∈ d
        if v isa AbstractVector
            for vi ∈ v
                @yield k => vi
            end
        else
            @yield k => v
        end
    end
end
# Returns each index of a list, but not for single values
_eachlistindex(X::AbstractArray) = eachindex(X)
_eachlistindex(x::Nothing) = [] # null values are not iterable in R
_eachlistindex(x) = 1
# Retuns an index of a list but not for julia-indexable values
_getlistindex(X::AbstractVector, n::Int) = getindex(X, n)
_getlistindex(x, n::Int) = isone(n) ? x : missing # or should we return missing?

### Main data cleaning function

## Note to consider: *_column as kwargs or normal args?
# on one hand, kwargs may imply that it would work without them
# which it would not.  On the other hand, kwargs make the
# function more readable, both in this code and in practice.
function make_clean_data(
    data::DataFrame;
    participant_column = nothing,
    trackloss_column = nothing,
    time_column = nothing,
    trial_column = nothing,
    aoi_columns = nothing,
    treat_non_aoi_looks_as_missing = nothing,
    item_columns = nothing
    )
    
    ## Data options:
    data_options = Dict{Symbol, Any}(
        :participant_column => participant_column,
        :trackloss_column => trackloss_column,
        :time_column => time_column,
        :trial_column => trial_column,
        :item_columns => item_columns,
        :aoi_columns => aoi_columns,
        :treat_non_looks_as_missing => treat_non_aoi_looks_as_missing
        )
    
    ## Check for reserved column name:
    if data_options[:time_column] == "Time"
        throw(error("""
            We apologise for the invonvenience, but your `time_column` cannot be called 'Time'.
            This name is a reserved name that EyeTrackingUtils uses.  Please rename.
        """))
    end
    
    if "Time" ∈ names(data)
        @warn """
        Your dataset has a column called 'time', but this column
        is reserved for EyeTrackingUtils.  Will rename to 'TimeOriginal'...
        """
        rename!(data, Dict(:Time => "TimeOriginal"))
    end
    
    ## Verify columns:
    out = copy(data)
    col_type_converter = Dict{Symbol, Function}(
        :participant_column => x -> _check_then_convert(x, _iscategorical, categorical!, "Participants"), # previously a data column
        :time_column => x -> _check_then_convert(x, _isnumeric, _asnumeric!, "Time"), # previously a data column
        :trial_column => x -> _check_then_convert(x, _iscategorical, categorical!, "Trial"), # previously a data column
        :trackloss_column => x -> _check_then_convert(x, _islogical2, _aslogical, "Trackloss"),
        :item_columns => x -> _check_then_convert(x, _iscategorical, categorical!, "Item"), # previously a data column
        :aoi_columns => x -> _check_then_convert(x, _islogical2, _aslogical, "AOI")
    )
    
    # for col in keys(col_type_converter)
    #     for i in _seq_along(data_options[col])
    #         if data_options[col] isa AbstractArray
    #             if isnothing(out[data_options[col][i]])
    #                 throw(error("Data are missing: $(col)"))
    #             end
    #             out[data_options[col][i]] = col_type_converter[col](out[data_options[col][i]])
    #         else
    #             if isnothing(out[data_options[col]])
    #                 throw(error("Data are missing: $(col)"))
    #             end
    #             out[data_options[col]] = col_type_converter[col](out[data_options[col]])
    #         end
    #     end
    # end
    for col in keys(col_type_converter)
        for i in _eachlistindex(data_options[col])
            if isnothing(out[_getlistindex(data_options[col], i)])
                throw(error("Data are missing at column $(_getlistindex(data_options[col], i))"))
            end
            println("Checking $col at $(data_options[col]) at $(_getlistindex(data_options[col], i))")
            out[_getlistindex(data_options[col], i)] = col_type_converter[col](out[_getlistindex(data_options[col], i)])
        end
    end
    
    
    
    ## Deal with non-AOI looks:
    if treat_non_aoi_looks_as_missing
        # any_aoi = sum(, dims=2) > 0 ? # second dimension is the sum of the rows
        any_aoi = sum(skipmissing.(out[data_options[aoi_columns]]), dims = 1) .> 0
        out[data_options[Symbol(trackloss_column)]][!any_aoi] .= true
    end
    
    ## Set All AOI rows with trackloss to NA:
    # this ensures that any calculations of proportion-looking will not include trackloss in the denominator
    for aoi in data_options[aoi_columns]
        out.aoi[out.data_options[trackloss_column]] = missing # or nothing?
    end
    
    # Check for duplicate values of Trial column within Participants
    duplicates = @> out begin
        groupby([:participant_column, :trial_column, :time_column])
        combine(nrow => :n)
        @where :n .> 1
    end
    
    if nrow(duplicates) > 0
        println(duplicates)
        throw(error("""
        It appears that `trial_column` is not unique within participants. See above for a summary
        of which participant*trials have duplicate timestamps. EyeTrackingUtils requires that each participant
        only have a single trial with the same `trial_column` value. If you repeated items in your experiment,
        use `item_column` to specify the name of the item, and set `trial_column` to a unique value
        (e.g., the trial index).
        """))
    end
    
    out = @> out begin
        groupby([:participant_column, :trial_column, :time_column])
    end
    
end


struct eR_data_eR_df
    out::DataFrame
    eR
end

## Assign attribute:
# class(out) <- c("eyetrackingR_data", "eyetrackingR_df", class(out))
# attr(out, "eyetrackingR") <- list(data_options = data_options)
# return(out)
