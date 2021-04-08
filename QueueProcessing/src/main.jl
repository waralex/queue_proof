import JSON3
import Redis
include("config.jl")
include("connection.jl")
include("processor.jl")

function simple_handler(data)
    sleep(data["sleep_for"])
    return data["expected_result"]
end

function mainloop(config)
end

conn = TaskConnection(CONFIG)
processor = TaskProcessor(conn, simple_handler)
run(processor)