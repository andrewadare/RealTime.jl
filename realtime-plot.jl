#!/usr/bin/env julia

using Plots
using ZMQ
using LibSerialPort

include("util/conversions.jl") # For csv2dict and keys_ok

"""
Return a ZMQ.Socket
"""
function get_data_source(context::ZMQ.Context, address::String, filter_key::String)

    # Create a subscriber socket and attempt connection to publisher
    socket = Socket(context, SUB)
    try
        ZMQ.connect(socket, address)  # URI like "tcp://localhost:5556"
    catch
        println("Could not open ZMQ socket at $address")
        quit()
    end
    # Subscribe to published messages, filtering on provided string
    ZMQ.set_subscribe(socket, filter_key)
    println("Connected to data publisher at $address")
    return socket
end

"""
Return a LibSerialPort.SerialPort
"""
function get_data_source(address::String, baud::Integer)
    sp = try
        open(address, baud)
    catch
        println("Could not open serial port at $address")
        quit()
    end
    return sp
end

# Define message accessors for different data sources
get_message(socket::ZMQ.Socket) = unsafe_string(ZMQ.recv(socket))
get_message(sp::SerialPort) = readuntil(sp, '\n', 100)

# Plot backend
gr(size=(900, 500))

context = Context()
data_source = get_data_source(context, "tcp://localhost:5556", "t:")
fields = ["t","y","s"]

# Number of points to display
n = 500

# Values for horizontal (time) axis
x = Float64[]

# Data
y, s = Float64[], Float64[]

while true
    # Get message as a String and convert to a Dict
    msg = get_message(data_source)
    d = csv2dict(msg, fields)

    # Validate
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
         title="Data stream",
         xaxis="time [s]",
         yaxis=("example [units]", (-1.1, 1.1), -1:0.25:1), # title, lims, ticks
         labels=(["Measured","Filtered"]), # legend
         line=([1 2], [:steppre :path], ["gray" "crimson"], [1.0 0.5]), # weights, types, colors, alphas
         fill=(0, [0.1 0], "dodgerblue"), # y-origin, alpha, colors
         )

    # Update the plot window
    gui()
end
