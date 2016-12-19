
# Functions like read and readline are blocking, but they can be made nonblocking with Tasks.

while true

    # Read one character. Enter is required after the character.
    # @async begin
    #     a = read(STDIN, Char)
    #     println("got $a")
    # end

    # Read one line. String includes the \n.
    @async begin
        a = readline(STDIN)
        println("got $a (length $(length(a)))")
    end

    # println("doing things") # Not blocked!
    sleep(0.1)

end
