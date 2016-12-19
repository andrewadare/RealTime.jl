using ZMQ
using LibSerialPort

# Message accessors for ZMQ and SerialPort
get_message(socket::ZMQ.Socket) = String(unsafe_string(ZMQ.recv(socket)))
get_message(sp::SerialPort) = readuntil(sp, '\n', 100)

"""
Return a ZMQ subscriber socket for the provided address.
All messages except those beginning with filter_prefix will be ignored.
If filter_prefix is an empty string (the default), no messages are ignored.
"""
function get_data_source(context::ZMQ.Context, address::String, filter_prefix::String="")

    # Create a subscriber socket and attempt connection to publisher
    socket = Socket(context, SUB)
    try
        ZMQ.connect(socket, address)
    catch
        println("Could not open ZMQ socket at $address")
        quit()
    end

    # Subscribe to published messages, filtering on provided filter_prefix string
    ZMQ.set_subscribe(socket, filter_prefix)

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
