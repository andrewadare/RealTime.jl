#!/usr/bin/env julia

println("Loading dependencies...")

using Plots
using LibSerialPort

# Plot backend
gr(size=(900, 500))

address = length(ARGS) == 1 ? ARGS[1] : "/dev/cu.usbmodem1421"

mcu = open(address, 115200)

# Number of points to display
n = 500

# Values for horizontal (time) axis and data
x = Float64[]
y, s = Float64[], Float64[]

function readmcu(sp::SerialPort)
    # Get message as a String, split to array
    msg = readuntil(mcu, '\n', 100)
    data = zeros(Float64, 3)
    try
        data = [parse(Float64, x) for x in split(msg)]
    catch
        println("Skipping: $msg")
        return
    end
    length(data) == 3 || return
    time, y1, y2 = data

    # println("$time, $y1, $y2")

    # Manage arrays as FIFO queues
    push!(x, time/1000) # ms to seconds
    push!(y, y1/1023)
    push!(s, y2/1023)
    if length(x) > n
        for v in (x, y, s)
            shift!(v)
        end
    end
end

function rtplot(x, y, s)
    plot(x, [y,s],
         title="Data stream", # Not displaying with GR backend (?)
         xaxis="time [s]",
         yaxis=("example [units]", (-0.2, 1.2)), # title, limits
         labels=(["Measured","Filtered"]), # legend
         line=([1 2], [:steppre :path], ["gray" "crimson"], [1.0 0.5]), # lineweights, linetypes, colors, alphas
         fill=(0, [0.1 0], "dodgerblue"), # y-origin, alpha, colors
         )
    # Update the plot window
    gui()
end

println("Creating plot...")
readmcu(mcu)
rtplot(x,y,s)

println("Ready")

while true

    @async begin
        a = readline(STDIN)
        a == "q\n" && quit()
        write(mcu, "$a")
    end

    @async begin
        readmcu(mcu)
        rtplot(x,y,s)
    end

    # Give the queued tasks a chance to run
    sleep(0.001)
end
