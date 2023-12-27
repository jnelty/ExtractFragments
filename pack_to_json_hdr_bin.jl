using CSV, DataFrames
include("readfiles.jl")
include("read_write_mkp.jl")

mutable struct Required
    filename::String
    leadsN::Int
    fs::Float64
    type::DataType
    len::Int
    leadnames::Vector{Symbol}

    function Required(filename::String, leadsN::Int, fs::Float64, type::DataType, len::Int, leadnames::Vector{Symbol})
        new(filename, leadsN, fs, type, len, leadnames)
    end
end

function get_folder_list(path::String)
    filelist = readdir(path)
    all_folders = filter(x->!('.' in lowercase(x)), filelist)
    return all_folders
end

function get_bin_files(dir::String)
    filelist = readdir(dir)
    allbinfiles = filter(x -> endswith(lowercase(x), ".bin"), filelist)
    allbinfiles = map(x -> splitext(x)[1], allbinfiles)
    return allbinfiles 
end

function get_qs_files(dir::String)
    filelist = readdir(dir)
    allbinfiles = filter(x -> endswith(lowercase(x), ".qs"), filelist)
    allbinfiles = map(x -> splitext(x)[1], allbinfiles)
    return allbinfiles 
end


function _readhdr(filepath::AbstractString)
    filename = split(split(filepath, "/")[end], ".")[1] |> String

    str = open(filepath, "r") do io
        len = stat(filepath).size
        bytes = Vector{UInt8}(undef, len)
        readbytes!(io, bytes, len)
        if bytes[1:3] == [0xEF, 0xBB, 0xBF] # проверка на UTF-8 BOM и пропуск
            bytes = bytes[4:end]
        end
        str = Array{Char}(bytes) |> x->String(x)
    end
    io = IOBuffer(str)
    lines = readlines(io) #, enc"windows-1251") # read and decode from windows-1251 to UTF-8 string

    lines = rstrip.(lines)

    delim = (' ', '\t')
    ln = split(lines[1], delim)
    num_ch, fs, lsb = parse(Int, ln[1]), parse(Float64, ln[2]), parse(Float64, ln[3])
    type = Int32
    # if (length(ln) > 3) # optional field
    #     type = string2datatype[ln[4]]
    # end

    ln = split(lines[2], delim)
    ibeg, iend = parse(Int, ln[1]), parse(Int, ln[2])
    timestart = parse(DateTime, ln[3])

    names = String.(split(lines[3], delim))
    lsbs = parse.(Float64, split(lines[4], delim))
    units = String.(split(lines[5], delim))

    if num_ch != length(names) # фикс, если в начале указано неверное кол-во каналов
        num_ch = length(names)
    end

    length(names) == length(lsbs) == length(units) || error("разное количество полей")

    # return num_ch, fs, ibeg, iend, timestart, names, lsbs, units, type
    # return (filename = filename, leadsN = num_ch, fs = fs, type = type, len = iend - ibeg + 1, leadnames = names), lsbs, ibeg, timestart, units
    return Required(filename, num_ch, fs, type, iend - ibeg + 1, Symbol.(names)), lsbs, ibeg, timestart, units
end

removext(x::String) = splitext(x)[1]
function make_hdr(
    required::Required,
    lsbs::Float64 = 1.0000,
    ibeg::Int = 0,
    timeStart::DateTime = DateTime(2023),
    units::Vector{Symbol} = Symbol[])

    filename, leadsN, fs, type, len, leadnames = required.filename, required.leadsN, required.fs, required.type, required.len, required.leadnames

    if lastindex(leadnames) != leadsN return err("!") end
    if !isempty(units)
        if lastindex(units) != leadsN return err("!") end
    else
        units = fill("unit", leadsN)
    end

    open(removext(filename)*".hdr", "w") do io
        write(io, join((leadsN, fs, lsbs), '\t')) + write(io, '\n')
        write(io, join((ibeg, len, timeStart), '\t')) + write(io, '\n')
        write(io, join(leadnames, '\t')) + write(io, '\n')
        write(io, join(fill(lsbs, leadsN), '\t')) + write(io, '\n')
        write(io, join(units, '\t')) + write(io, '\n')
    end
end

function rewrite_fragment_positions_hdr(hdr_path::String, path_save::String, sample_start::Int, len::Int, c::String = "")
    required, lsbs, ibeg, timestart, units = _readhdr(hdr_path)
    ibeg = sample_start
    required.len = len

    required.filename = path_save * required.filename * c

    make_hdr(required, lsbs[1], ibeg, timestart, Symbol.(units))
end

function write_bin(signals::NamedTuple, filename::String)

    type = Int32

    ecgs = [signals[ln] .|> round .|> Int32 for ln in keys(signals)]

    data = Matrix{typeof(ecgs[1][1])}(undef, lastindex(ecgs), lastindex(ecgs[1]))
    [[data[i,j] = ecgs[i][j] for i in 1:lastindex(ecgs)] for j in 1:lastindex(ecgs[1])];

    write(filename, htol.(data))
end

function write_cut_bin(bin_path::String, save_path::String, ibeg::Int, len::Int, c::String = "")
    signals, _, _, _ = _readbin(bin_path, ibeg:ibeg + len)
    
    bin_filename = split(split(bin_path, "/")[end], ".")[1] |> String
    write_bin(signals, save_path * bin_filename * c * ".bin")
end

function create_json_hdr_bin_by_all_fragments(base_path::String, mkp_path::String, save_path::String = nothing)
    all_bases = get_folder_list(base_path)

    for base in all_bases
        data_path = base_path * base * "/bin/"
        base_mkp_path = mkp_path * base * "/"
        if isnothing(save_path) base_save_path = base_mkp_path 
        else base_save_path = save_path * base * "/" end

        ver_marks_base_path = "$base_path$base/marks/"
        bin_files = get_bin_files(data_path)
        qs_files = get_qs_files(ver_marks_base_path)

        for file in bin_files
            bin_path = data_path * file * ".bin"
            hdr_path = data_path * file * ".hdr"
            bin_mkp_path = base_mkp_path * file * "/"
            save_mkp_path = base_save_path * file * "/"
            
            if file in qs_files
                marks_path = "$base_path$base/marks/$file.qs"
                marks = CSV.File(marks_path) |> DataFrame
            else
                continue
            end

            intervals = CSV.File(bin_mkp_path * file * ".csv", header = [:start, :finish, :label]) |> DataFrame

            c = 1
            for interval in eachrow(intervals)
                interval_info = find_qrs_positions(file, marks, interval)
                write_markup(interval_info, save_mkp_path * "$(file)_$c.json")
                ibeg = interval.start
                len = interval.finish - interval.start
                rewrite_fragment_positions_hdr(hdr_path, save_mkp_path, ibeg, len, "_$c")
                write_cut_bin(bin_path, save_mkp_path, ibeg, len, "_$c")
                c += 1
            end

        end
    end
end

