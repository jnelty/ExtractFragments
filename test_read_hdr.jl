filepath = "D:/ECGBase/ВерификацияВЖблокад_часть(10шт)/bin/8s000726.hdr"
filepath_bin = "D:/ECGBase/ВерификацияВЖблокад_часть(10шт)/bin/8s000726.bin"
writepath = "./"
using Dates, CSV, DataFrames
include("readfiles.jl")
signal, fs, _, _ = readbin("./8s000726.bin")
length(signal.C6)

readhdr(filepath)
readhdr("./8s000726.hdr")
removext(x::String) = splitext(x)[1]
split(split(filepath, "/")[end], ".")[1]
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

return num_ch, fs, ibeg, iend, timestart, names, lsbs, units, type

required = (filename = filename, leadsN = num_ch, fs = fs, type = type, len = len, leadname = names)


required, lsbs, ibeg, timestart, units = readhdr(filepath)
required
readhdr(filepath)

function rewrite_fragment_positions_hdr(hdr_path::String, path_save::String, sample_start::Int, len::Int)
    required, lsbs, ibeg, timestart, units = readhdr_(hdr_path)
    ibeg = sample_start
    required.len = len
    required.filename = path_save * required.filename

    make_hdr(required, lsbs[1], ibeg, timestart, Symbol.(units))
end

function write_bin(signals::NamedTuple, filename::String)

    type = Float64

    ecgs = [signals[ln] .|> type for ln in keys(signals)]

    data = Matrix{typeof(ecgs[1][1])}(undef, lastindex(ecgs), lastindex(ecgs[1]))
    [[data[i,j] = ecgs[i][j] for i in 1:lastindex(ecgs)] for j in 1:lastindex(ecgs[1])];

    write(filename, htol.(data))
end

write_bin(signal, writepath * "8s000726")
signal

rewrite_fragment_positions_hdr(filepath, writepath, 300000, 310000)

