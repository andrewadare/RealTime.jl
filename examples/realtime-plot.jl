#!/usr/bin/env julia

# Load directly while developing. Once stable, add module using Pkg.clone()
# and remove this line.
include("../src/RealTime.jl")

using Plots
using ZMQ
using LibSerialPort
using RealTime
using JSON

# Plot backend
gr(size=(900, 500))

context = Context()
data_source = get_data_source(context, "tcp://localhost:5556")

# Number of points to display
n = 500

# Values for horizontal (time) axis and data
x = Float64[]
y, s = Float64[], Float64[]

while true
    # Get message as a String and convert to a Dict
    msg = get_message(data_source)
    d = JSON.parse(msg)

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
