using CSV, DataFrames, Plots, Statistics
include("get_data.jl")

function get_intervals(path::String, base_number::Int, record_number::Int)
    bases = get_folders(path)
    base = bases[base_number]
    base_records = get_folders("$path/$base")
    base_record = base_records[record_number]
    println("base: $base")
    println("record: $base_record")

    mkp = CSV.File("$path/$base/$base_record/$base_record.csv", header = [:start, :finish, :label])

    return DataFrame(mkp)
end

function write_intervals(path::String, mkp::DataFrame, base_number::Int, record_number::Int)
    bases = get_folders(path)
    base = bases[base_number]
    base_records = get_folders("$path/$base")
    base_record = base_records[record_number]

    CSV.write("$path/$base/$base_record/$base_record.csv", mkp, header = false)
end

function plot_intervals(signal::NamedTuple, marks::DataFrame, intervals::DataFrame)

    for interval in eachrow(intervals)
        start, finish = interval.start, interval.finish
        display_signal_interval(signal, marks, start, finish)
    end
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

function find_qrs_positions(record_name::String, marks::DataFrame, interval::DataFrameRow)
    len = interval.finish - interval.start
    ibeg = interval.start
    qrs_onsests = marks[marks.Q .>= interval.start .&& marks.Q .<= interval.finish, :Q] .- ibeg .+ 1
    qrs_finish = marks[marks.Q .>= interval.start .&& marks.Q .<= interval.finish, :S] .- ibeg .+ 1
    forms = marks[marks.Q .>= interval.start .&& marks.Q .<= interval.finish, :Form]
    # println(forms) 
    label = ismissing(interval.label) ? "-" : interval.label
    
    if length(qrs_onsests) != length(forms)
        println("error")
    end

    return (record_name = record_name, ibeg = ibeg, length = len, QRS_onset = qrs_onsests, QRS_end = qrs_finish, QRS_form = forms, Noise = label)
end

# path_to_ecg_base = "D:/ECGBase/"
# base_number = 4
# record_number = 2
# base_name, record_name = get_base_record_name(path_to_ecg_base, base_number, record_number)
# signal, fs = get_data(path_to_ecg_base, base_number, record_number);
# marks = get_marks(path_to_ecg_base, base_number, record_number - 1);
# intervals = get_intervals("selected/", base_number, record_number)
# plot_intervals(signal, marks, intervals)
# write_intervals("selected/", intervals, base_number, record_number)

using JSON3

function write_markup(markup, filename::String)
    open(filename, "w") do io
        JSON3.pretty(io, markup)
    end
end

# out = []
# base_number = 4
# record_number = 6
# base_name, record_name = get_base_record_name(path_to_ecg_base, base_number, record_number)
# signal, fs = get_data(path_to_ecg_base, base_number, record_number);
# marks = get_marks(path_to_ecg_base, base_number, record_number - 1);
# intervals = get_intervals("selected/", base_number, record_number)
# plot_intervals(signal, marks, intervals)

# for interval in eachrow(intervals)
#     interval_info = find_qrs_positions(record_name, marks, interval)
#     push!(out, interval_info)
# end

# base_number = 1
# record_number = 4
# signal, fs = get_data(path_to_ecg_base, base_number, record_number);
# marks = get_marks(path_to_ecg_base, base_number, record_number);
# intervals = get_intervals("selected/", base_number, record_number)
# plot_intervals(signal, marks, intervals)

# base_number = 3
# record_number = 1
# base_name, record_name = get_base_record_name(path_to_ecg_base, base_number, record_number)
# out = []
# for record_number = 1:12
#     base_name, record_name = get_base_record_name(path_to_ecg_base, base_number, record_number)
#     intervals = get_intervals("selected/", base_number, record_number)
#     marks = get_marks(path_to_ecg_base, base_number, record_number);
#     println(intervals)
#     for interval in eachrow(intervals)
#         interval_info = find_qrs_positions(record_name, marks, interval)
#         push!(out, interval_info)
#     end
# end

# out
# save_dir = "./mkp/"
# write_markup(out, save_dir * "$base_name.json")

# base_name