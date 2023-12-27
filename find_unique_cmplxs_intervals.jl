include("get_data.jl")
using Plots, DataFrames

struct Interval
    start::Int
    finish::Int
    unique_cmplxs::Vector{String}
end

function calc_unique_cmplx_counts(marks::DataFrame)
    forms = unique(marks.Form) |> Vector{String}
    counts = []
    # remove_noise_cmplxs!(forms)
    for form in forms
        count_form = sum(marks.Form .== form)
        push!(counts, count_form)
    end

    return Dict{String, Int}(zip(forms, counts))
end


function find_complx_intervals(marks::DataFrame, fs::Union{Int, Float64})
    time_len = TIME_LEN
    window = fs * time_len 
    unique_intervals = Interval[]


    for row in eachrow(marks)
        pos_Q = row.Q
        form_marks_from_interval = marks[marks.Q .>= pos_Q .&& marks.Q .<= pos_Q + window, :Form]
        unique_cmplxs = unique(form_marks_from_interval) |> Vector{String}

        if !noise_cmplxs_in(unique_cmplxs)
            push!(unique_intervals, Interval(pos_Q, pos_Q + window, unique_cmplxs))
        end


    end
    
    return unique_intervals
end

function noise_cmplxs_in(forms::Vector{String})
    return "Z" in forms || "X" in forms || "ZX" in forms || "Z2" in forms || "Z1" in forms || "Z3" in forms
end

function find_intervals_with_form(intervals_forms::DataFrame, cmplx_form::String)
    intervals_forms = intervals_forms[
        map(interval_cmplxs -> cmplx_form in interval_cmplxs, 
        intervals_forms.unique_cmplxs), :]
end

function calc_form_count_in_interval(marks::DataFrame, intervals::DataFrame, form::String)

    interval_counts = []
    for interval in eachrow(intervals)
        forms = get_cmplx_forms_from_range(marks, interval.start, interval.finish)
        count_form = sum(forms .== form)
        push!(interval_counts, count_form)
    end

    intervals.form_count = interval_counts

    return intervals
end

function remove_noise_cmplxs!(forms::Vector{String})
    if ("Z" in forms) remove!(forms, "Z") end
    if ("X" in forms) remove!(forms, "X") end
    if ("ZX" in forms) remove!(forms, "ZX") end
    if ("Z1" in forms) remove!(forms, "Z1") end
    if ("Z2" in forms) remove!(forms, "Z2") end
    if ("Z3" in forms) remove!(forms, "Z3") end
    return forms
end 
remove!(array::Array, item) = filter!(el -> el != item, array)

using Plots, Statistics
# plotly()
function display_signal_interval(signal::NamedTuple, marks::DataFrame, samp_start::Int, samp_finish::Int, std::Float64)
    channels = keys(signal)
    shift = 0
    f = plot();

    for ch in channels
        # plot!(signal[ch][samp_start:samp_finish] .- mean(signal[ch][samp_start:samp_finish]) .- shift, label = "$ch");
        plot!(signal[ch][samp_start:samp_finish] .- mean(signal[ch][samp_start:samp_finish]) .- shift, label = false);
        shift += 2500
    end

    marks_from_interval = marks[marks.Q .>= samp_start .&& marks.Q .<= samp_finish, :]
    
    time_Q = marks_from_interval.Q
    hline!([2500], linecolor = nothing, label = false)
    annotate!(time_Q .- samp_start, fill(2500, length(time_Q)), text.(Vector{String}(marks_from_interval.Form), 8))
    title!("base: $base_number record: $record_number std: $std $samp_start - $samp_finish")
    display(f)
end

function display_signal_interval(signal::NamedTuple, marks::DataFrame, samp_start::Int, samp_finish::Int)
    channels = keys(signal)
    shift = 0
    f = plot();

    for ch in channels
        # plot!(signal[ch][samp_start:samp_finish] .- mean(signal[ch][samp_start:samp_finish]) .- shift, label = "$ch");
        plot!(signal[ch][samp_start:samp_finish] .- mean(signal[ch][samp_start:samp_finish]) .- shift, label = false);
        shift += 2500
    end

    marks_from_interval = marks[marks.Q .>= samp_start .&& marks.Q .<= samp_finish, :]
    
    time_Q = marks_from_interval.Q
    hline!([2500], linecolor = nothing, label = false)
    annotate!(time_Q .- samp_start, fill(2500, length(time_Q)), text.(Vector{String}(marks_from_interval.Form), 8))
    title!("base: $base_number record: $record_number $samp_start - $samp_finish")
    display(f)
end

function flat_to_one_vector(vectors::Vector{Vector{String}})
    out = []
    for vect in vectors
        append!(out, vect)
    end
    return out
end
get_cmplxs_beyond_intervals(unique_cmplxs_in_intervals, all_unique_cmplxs) = filter(cmplx -> !(cmplx in unique_cmplxs_in_intervals) , all_unique_cmplxs)

function find_cmplxs_beyond_intervals(intervals::DataFrame, marks::DataFrame)
    cmplxs = intervals.unique_cmplxs
    unique_cmplxs_in_intervals = unique(flat_to_one_vector(cmplxs))
    all_unique_cmplxs = collect(keys(calc_unique_cmplx_counts(marks)))
    remove_noise_cmplxs!(all_unique_cmplxs)
    beyound_complxs = get_cmplxs_beyond_intervals(unique_cmplxs_in_intervals, all_unique_cmplxs)

    return beyound_complxs
end



function calc_RR(QRS_onset::Vector{Int}, fs::Float64)

    out = Vector{Union{Int64, Missing}}(undef, lastindex(QRS_onset))
    t0 = missing
    for (i, qtime) in enumerate(QRS_onset)
        out[i] = (qtime - t0) |> pnts_to_ms(fs)
        t0 = qtime
    end

    return out
end
pnts_to_s(fs) = x -> x / fs
pnts_to_ms(fs) = x -> x |> pnts_to_s(fs) |> x -> x*1000 |> x -> round(Union{Int, Missing}, x)

function calc_std_deviations(marks::DataFrame, intervals::DataFrame, fs::Float64 = 257.0)
    stds = Float64[]
    for interval in eachrow(intervals)
        time_Q = get_cmplx_onsets_from_range(marks, interval.start, interval.finish)
        std = calc_RR_std_deviation(time_Q, fs)
        push!(stds, std)
    end

    intervals.std = stds
    return intervals
end

function calc_RR_std_deviation(time_Q::Vector{Int}, fs::Float64)
    rrs = calc_RR(time_Q, fs)
    rrs = drop_missing(rrs) |> Vector{Int}
    n = length(rrs)
    mean_rr = mean(rrs)
    std = sqrt(sum((rrs .- mean_rr).^2) / n) 

    return round(std, digits=2)
end
drop_missing(vect::Vector) = filter(el -> !ismissing(el), vect)

function get_cmplx_onsets_from_range(marks::DataFrame, start::Int, finish::Int)
    qrs_onsests = marks[marks.Q .>= start .&& marks.Q .<= finish, :Q]

    return qrs_onsests
end

function get_cmplx_forms_from_range(marks::DataFrame, start::Int, finish::Int)
    forms = marks[marks.Q .>= start .&& marks.Q .<= finish, :Form]

    return forms
end