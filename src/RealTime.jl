module RealTime

export
    get_message,
    get_data_source,
    line2dict,
    csv2dict,
    keys_ok

include("conversions.jl")
include("accessors.jl")

end