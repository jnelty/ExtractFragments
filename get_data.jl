include("readfiles.jl")

function get_data(path_to_ecg_base::String, base_number::Int = 1, record_number::Int = 1)
    base, record = get_base_record_name(path_to_ecg_base, base_number, record_number)
    println("Selected base: $base")
    println("Selected record: $record")
    path_to_bin_data = "$path_to_ecg_base$base/bin/"
    signal, fs, _, _ = readbin(path_to_bin_data * record)

    return signal, fs
end

function get_base_record_name(path_to_ecg_base::String, base_number::Int = 1, record_number::Int = 1)
    bases = get_folders(path_to_ecg_base)
    base = bases[base_number]
    path_to_bin_data = "$path_to_ecg_base$base/bin/"
    records = get_bin_files(path_to_bin_data)
    record = records[record_number]

    return base, record
end

function get_bin_files(dir::String)
    filelist = readdir(dir)
    allbinfiles = filter(x->endswith(lowercase(x), ".bin"), filelist)
    allbinfiles = map(x -> splitext(x)[1], allbinfiles)
    return allbinfiles 
end

function get_marks(path_to_ecg_base::String, base_number::Int = 1, record_number::Int = 1)
    bases = get_folders(path_to_ecg_base)
    base = bases[base_number]
    path_to_qs_data = "$path_to_ecg_base$base/marks/"
    # println(path_to_qs_data)
    all_marks = get_qs_files(path_to_qs_data)
    # println(all_marks)
    marks = all_marks[record_number]
    println("Selected base: $base")
    println("Selected marks: $marks")
    marks = CSV.File(path_to_qs_data * marks)
    return DataFrame(marks)
end

function get_qs_files(dir::String)
    filelist = readdir(dir)
    allqsfiles = filter(x->endswith(lowercase(x), ".qs"), filelist)
    return allqsfiles 
end

function get_folders(dir::String)
    filelist = readdir(dir)
    all_folders = filter(x->!('.' in lowercase(x)), filelist)
    # allbinfiles = map(x -> splitext(x)[1], allbinfiles)
    return all_folders
end
