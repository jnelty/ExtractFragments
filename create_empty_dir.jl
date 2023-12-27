include("get_data.jl")
path_to_ecg_base = "D:/ECGBase"

function correlate_base_records(path_to_ecg_base::String)
    base_names = get_folders(path_to_ecg_base)
    
    base_records = Vector{String}[]
    for base_name in base_names
        records_names = get_bin_files("$path_to_ecg_base/$base_name/bin")
        push!(base_records, records_names)
    end

    return Dict{String, Vector{String}}(zip(base_names, base_records))
end

function create_empty_dir_ecg_base(path::String, base_records::Dict{String, Vector{String}})
    base_names = keys(base_records)
    for base_name in base_names
        mkdir("$path/$base_name")
        record_names = base_records[base_name]
        for record_name in record_names
            mkdir("$path/$base_name/$record_name")
        end
    end
end


# run
mkdir("fragments")
base_records = correlate_base_records(path_to_ecg_base)
create_empty_dir_ecg_base("./fragments/", base_records)