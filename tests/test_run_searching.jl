include("../find_unique_cmplxs_intervals.jl")

path_to_ecg_base = "D:/ECGBase/"
global TIME_LEN = 10 #seconds

base_number = 1
record_number = 3
signal, fs = get_data(path_to_ecg_base, base_number, record_number);
marks = get_marks(path_to_ecg_base, base_number, record_number);

function find_complx_intervals_(marks::DataFrame, fs::Union{Int, Float64})
    time_len = TIME_LEN
    window = fs * time_len 
    unique_intervals = Interval[]

    row_index_start = 1
    pos_start = marks[row_index_start, :].Q
    # pos_finish = pos_start

    for row in eachrow(marks)
        pos_Q = row.Q
        if (pos_Q > (pos_start + window)) 
            form_marks_from_interval = marks[marks.Q .>= pos_start .&& marks.Q .<= pos_start + window, :Form]
            unique_cmplxs = unique(form_marks_from_interval) |> Vector{String}

            if !noise_cmplxs_in(unique_cmplxs)
                push!(unique_intervals, Interval(pos_start, pos_finish, unique_cmplxs))
            end
            row_index_start += 1; 
            pos_start = marks[row_index_start, :].Q; 
        end

        # pos_finish = pos_Q
    end
    
    return unique_intervals
end


function plot_all(intervals::DataFrame, signal::NamedTuple, marks::DataFrame)
    count = 1
    for interval in eachrow(intervals)
        samp_start, samp_finish, std = interval.start, interval.finish, interval.std
        display_signal_interval(signal, marks, samp_start, samp_finish, std)
        savefig("./base_test/fragment_$count.png")
        count += 1
    end
end



#основной запуск

intervals = find_complx_intervals(marks, fs)
intervals_df = DataFrame(intervals)
unique_cmplx_counts = calc_unique_cmplx_counts(marks)

# поиск по комплексу
cmplx_form = "VL"
intervals_with_cmplx_form = find_intervals_with_form(intervals_df, cmplx_form)
# intervals_with_cmplx_form = find_intervals_with_form(intervals_with_cmplx_form, "V1")
intervals_with_cmplx_form.unique_cmplx_count = length.(intervals_with_cmplx_form.unique_cmplxs)
sorted_df = sort(intervals_with_cmplx_form, [:unique_cmplx_count], rev = false)
sorted_df = sort(intervals_with_cmplx_form, [:unique_cmplx_count], rev = true)
max_value = sorted_df[1, :unique_cmplx_count]
max_count_cmplx_intervals = intervals_with_cmplx_form[intervals_with_cmplx_form.unique_cmplx_count .== max_value - 1, :]
max_count_cmplx_intervals = intervals_with_cmplx_form[intervals_with_cmplx_form.unique_cmplx_count .== max_value, :]
calc_std_deviations(marks, intervals_with_cmplx_form, fs)
calc_std_deviations(marks, max_count_cmplx_intervals, fs)
sorted_cmplxs_by_std = sort(intervals_with_cmplx_form, [:std], rev = true)
sorted_cmplxs_by_std = sort(max_count_cmplx_intervals, [:std], rev = true)
find_cmplxs_beyond_intervals(max_count_cmplx_intervals, marks)

calc_form_count_in_interval(marks, sorted_cmplxs_by_std, cmplx_form)
sorted_by_form_counts = sort(sorted_cmplxs_by_std, [:form_count], rev = true)

plot_all(sorted_cmplxs_by_std, signal, marks)
plot_all(sorted_by_form_counts, signal, marks)
plot_all(max_count_cmplx_intervals, signal, marks)

# поиск участка с максимальным числом комлпексом
df = deepcopy(intervals) |> DataFrame
df.unique_cmplx_count = length.(df.unique_cmplxs)
sorted_df = sort(df, [:unique_cmplx_count], rev = true)
max_value = sorted_df[1, :unique_cmplx_count]
max_count_cmplx_intervals = df[df.unique_cmplx_count .== max_value - 1, :]
max_count_cmplx_intervals = df[df.unique_cmplx_count .== max_value, :]
calc_std_deviations(marks, max_count_cmplx_intervals, fs)
sorted_cmplxs_by_std = sort(max_count_cmplx_intervals, [:std], rev = true)
find_cmplxs_beyond_intervals(sorted_cmplxs_by_std, marks)
plot_all(sorted_cmplxs_by_std, signal, marks)





count = 1
for max_count_cmplx in eachrow(max_count_cmplx_intervals)
    samp_start, samp_finish = max_count_cmplx.start, max_count_cmplx.finish
    display_signal_interval(signal, marks, samp_start, samp_finish)
    savefig("./base_test/fragment_$count.png")
    count += 1
end

max_count_cmplx_intervals = df[df.unique_cmplx_count .== max_value - 1, :]
calc_std_deviations(marks, max_count_cmplx_intervals, fs)
sorted_cmplxs_by_std = sort(max_count_cmplx_intervals, [:std])
find_cmplxs_beyond_intervals(sorted_cmplxs_by_std, marks)

intervals_V2 = find_intervals_with_form(max_count_cmplx_intervals, "A")
sorted_cmplxs_by_std = sort(intervals_V2, [:std])

count = 1
for max_count_cmplx in eachrow(sorted_cmplxs_by_std)
    samp_start, samp_finish = max_count_cmplx.start, max_count_cmplx.finish
    display_signal_interval(signal, marks, samp_start, samp_finish)
    savefig("./base_test/fragment_$count.png")
    count += 1
end

display_signal_interval(signal, marks, 13695000, 13697570)
savefig("./selected/A_form")






count = 1
for row in 1500:1580
    row_interval = sorted_intervals_with_cmplx_form[row, :]
    samp_start, samp_finish = row_interval.start, row_interval.finish
    display_signal_interval(signal, marks, samp_start, samp_finish)
    # savefig("./base_test/base_id $base_number _record_id $record_number _$samp_start-$samp_finish.png")
    savefig("./base_test/fragment_$count.png")
end



count = 1
for max_count_cmplx in eachrow(max_count_cmplx_intervals)
    samp_start, samp_finish = max_count_cmplx.start, max_count_cmplx.finish
    display_signal_interval(signal, marks, samp_start, samp_finish)
    # savefig("./base_test/base_id $base_number _record_id $record_number _$samp_start-$samp_finish.png")
    savefig("./base_test/fragment_$count.png")
    count =+ 1
end

