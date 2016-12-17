#!/usr/bin/env julia

# Publish simulated data continuously over a ZMQ socket.
# Binds PUB socket to tcp://*:5556

using ZMQ

context = Context()
socket = Socket(context, PUB)
ZMQ.bind(socket, "tcp://*:5556")

time_ms() = round(Int, time_ns()/1e6)

alpha = 0.3 # Smoothing parameter in [0,1] (smaller is stronger)
start = time_ms()
ylist = zeros(2)

println("Sending data...")
while true

    # Random walk
    y = clamp(ylist[1] + 0.1*randn(), -1, 1)

    # Filtered value is a convex sum of current and historical time series data
    # http://www.itl.nist.gov/div898/handbook/pmc/section4/pmc431.htm
    s = alpha*y + (1 - alpha)*ylist[2]

    ylist = [y,s]

    # Print to console and send out the message string
    msg = "t:$(time_ms() - start),y:$y,s:$s"
    println(msg)
    ZMQ.send(socket, msg)

    sleep(0.02) # ~50 Hz
end

# Never reached
ZMQ.close(socket)
ZMQ.close(context)
