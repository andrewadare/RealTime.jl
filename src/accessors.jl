using ZMQ
using LibSerialPort

# Message accessors for ZMQ and SerialPort
get_message(socket::ZMQ.Socket) = unsafe_string(ZMQ.recv(socket))
get_message(sp::SerialPort) = readuntil(sp, '\n', 100)

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
