#!/usr/bin/env julia

using Plots
using ZMQ
using LibSerialPort

include("util/conversions.jl") # For csv2dict and keys_ok
include("util/accessors.jl") # For get_message and get_data_source

# Plot backend
gr(size=(900, 500))

context = Context()
data_source = get_data_source(context, "tcp://localhost:5556", "t:")
fields = ["t","y","s"]

# Number of points to display
n = 500

# Values for horizontal (time) axis and data
x = Float64[]
y, s = Float64[], Float64[]

while true
    # Get message as a String, convert to a Dict, and validate
    msg = get_message(data_source)
    d = csv2dict(msg, fields)
    keys_ok(d, fields) || continue

    # Manage arrays as FIFO queues
    push!(x, d["t"]/1000) # ms to seconds
    push!(y, d["y"])
    push!(s, d["s"])
    if length(x) > n
        for v in (x, y, s)
            shift!(v)
        end
    end

    plot(x, [y,s],
         title="Data stream", # Not displaying with GR backend (?)
         xaxis="time [s]",
         yaxis=("example [units]", (-1.1, 1.1), -1:0.25:1), # title, limits, ticks
         labels=(["Measured","Filtered"]), # legend
         line=([1 2], [:steppre :path], ["gray" "crimson"], [1.0 0.5]), # lineweights, linetypes, colors, alphas
         fill=(0, [0.1 0], "dodgerblue"), # y-origin, alpha, colors
         )

    # Update the plot window
    gui()
end
