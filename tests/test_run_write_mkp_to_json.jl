include("../read_write_mkp.jl")

path_to_ecg_base = "D:/ECGBase/"
base_number = 4
record_number = 2
base_name, record_name = get_base_record_name(path_to_ecg_base, base_number, record_number)
signal, fs = get_data(path_to_ecg_base, base_number, record_number);
marks = get_marks(path_to_ecg_base, base_number, record_number - 1);
intervals = get_intervals("selected/", base_number, record_number)
plot_intervals(signal, marks, intervals)
write_intervals("selected/", intervals, base_number, record_number)



out = []
base_number = 4
record_number = 6
base_name, record_name = get_base_record_name(path_to_ecg_base, base_number, record_number)
signal, fs = get_data(path_to_ecg_base, base_number, record_number);
marks = get_marks(path_to_ecg_base, base_number, record_number - 1);
intervals = get_intervals("selected/", base_number, record_number)
plot_intervals(signal, marks, intervals)

for interval in eachrow(intervals)
    interval_info = find_qrs_positions(record_name, marks, interval)
    push!(out, interval_info)
end

base_number = 1
record_number = 4
signal, fs = get_data(path_to_ecg_base, base_number, record_number);
marks = get_marks(path_to_ecg_base, base_number, record_number);
intervals = get_intervals("selected/", base_number, record_number)
plot_intervals(signal, marks, intervals)

base_number = 3
record_number = 1
base_name, record_name = get_base_record_name(path_to_ecg_base, base_number, record_number)
out = []
for record_number = 1:12
    base_name, record_name = get_base_record_name(path_to_ecg_base, base_number, record_number)
    intervals = get_intervals("selected/", base_number, record_number)
    marks = get_marks(path_to_ecg_base, base_number, record_number);
    println(intervals)
    for interval in eachrow(intervals)
        interval_info = find_qrs_positions(record_name, marks, interval)
        push!(out, interval_info)
    end
end

out
save_dir = "./mkp/"
write_markup(out, save_dir * "$base_name.json")

base_name