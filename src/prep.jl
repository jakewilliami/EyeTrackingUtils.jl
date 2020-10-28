#!/usr/bin/env bash
    #=
    exec julia --project="$(realpath $(dirname $0))" --color=yes --startup-file=no -e "include(popfirst!(ARGS))" \
    "${BASH_SOURCE[0]}" "$@"
    =#
    
using DataFrames
using Query

using Lazy: @> # or using DataConvenience: @>, but Lazy exports groupby
using DataFramesMeta: @where
using Statistics: mean

_isbool(x)::Bool = isequal(x, true) || isequal(x, false) ? true : false
_iscategorical(df::DataFrame, x)::Bool = isa(df.x, CategoricalArray)

function _islogical(x)::Bool
    if _isbool(x)
        return true
    elseif isnumeric(x)
    else
        throw(error("""
            One of your columns ($(col)) could not be converted
            to the correct format (Bool).  Please do so manually.
        """))
    end
end

_asnumeric(x) = parse(Float64, x)
_aslogical(x) = parse(Bool, x)

function _check_then_convert(
    df::DataFrame,
    x,
    check_function::Function,
    convert_function::Function,
    colname::Union{String, Symbol}
    )
    
    if ! check_function(df, x)
        println("Converting $(colname) to proper type...")
        x = convert_function(df, Symbol(x))
        println("...done")
    end
    
    if colname == "Trackloss" && any(isnothing(x))
        @warn "Found NAs in trackloss column.  These will be treated as TRACKLOSS = false."
        x = isnothing(x) ? false : x
    end
    
    return x
end

function _check_then_convert(
    x,
    check_function::Function,
    convert_function::Function,
    colname::Union{String, Symbol}
    )
    
    if ! check_function(x)
        println("Converting $(colname) to proper type...")
        x = convert_function(x)
        println("...done")
    end
    
    if colname == "Trackloss" && any(isnothing(x))
        @warn "Found NAs in trackloss column.  These will be treated as TRACKLOSS = false."
        x = isnothing(x) ? false : x
    end
    
    return x
end

function make_clean_data(
    data,
    participant_column,
    trackloss_column,
    time_column,
    trial_column,
    aoi_columns,
    treat_non_aoi_looks_as_missing;
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
        :treat_non_looks_as_missing => treat_non_looks_as_missing
        )
    
    ## Check for reserved column name:
    if data_options[:time_column] == "Time"
        throw(error("""
            We apologise for the invonvenience, but your `time_column` cannot be called 'Time'.
            This name is a reserved name that EyeTrackingUtils uses.  Please rename.
        """))
    end
    
    if "Time" ∈ names(data)
        @warn """Your dataset has a column called 'time', but this column
        is reserved for EyeTrackingUtils.  Will rename to 'TimeOriginal'...
        """
        rename!(data, Dict(:Time => "TimeOriginal"))
    end
    
    ## Verify columns:
    out = copy(data)
    col_type_converter = Dict{Symbol, Function}(
        :participant_column => x -> _check_then_convert(data, x, _iscategorical, categorical!, "Participants"),
        :time_column => x -> _check_then_convert(data, x, isnumeric, _asnumeric, "Time"),
        :trial_column => x -> _check_then_convert(data, x, _iscategorical, categorical!, "Trial"),
        :trackloss_column => x -> _check_then_convert(x, _isbool, _aslogical, "Trackloss"),
        :item_columns => x -> _check_then_convert(data, x, _iscategorical, categorical!, "Item"),
        :aoi_columns => x -> _check_then_convert(x, _isbool, _aslogical, "AOI")
    )
    
    for col in keys(col_type_converter)
        for i in 1:length(data_options[col])
            if isnothing(out.data_options[Symbol(col)][i])
                throw(error("Data are missing: $(col)"))
            end
            
            out.data_options = col_type_converter[Symbol(col)](out.data_options[Symbol(col)][i])
        end
    end
    
    ## Deal with non-AOI looks:
    if treat_non_aoi_looks_as_missing
        any_aoi = sum(, dims=2) > 0 ? # second dimension is the sum of the rows
        any_aoi = sum.(skipmissing.(eachrow(out.data_options[Symbol(aoi_columns)]))) > 0
        out.data_options[Symbol(trackloss_column)](!any_aoi) = true
    end
    
    ## Set All AOI rows with trackloss to NA:
    # this ensures that any calculations of proportion-looking will not include trackloss in the denominator
    for aoi in data_options[Symbol(aoi_columns)]
        out.aoi[out.data_options[Symbol(trackloss_column)]] = missing # or nothing?
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
