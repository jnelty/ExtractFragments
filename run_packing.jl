include("pack_to_json_hdr_bin.jl")

base_path = "D:/ECGBase/"
fragment_path = "./selected/"
save_path = "./fragments/"

create_json_hdr_bin_by_all_fragments(base_path, fragment_path, save_path)