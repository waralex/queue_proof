mutable struct TaskProcessor
    conn ::TaskConnection
    handler ::Function
    tasks_runing ::Threads.Atomic{Int64}
    TaskProcessor(conn, handler) = new(conn, handler, Threads.Atomic{Int64}(0))
end

function proccess_task(processor::TaskProcessor, task)
    processor.tasks_runing[] += 1
    st = time_ns()
    @info "task started" task_id=task["task_id"] runing_tasks = processor.tasks_runing[]
    result = processor.handler(task)
    set_result(processor.conn, task["task_id"], result)
    processor.tasks_runing[] -= 1
    @info "task ended" task_id=task["task_id"] runing_tasks = processor.tasks_runing[] elapsed = (time_ns() - st) / 1e9
end

function run(processor::TaskProcessor)
    @info "mainloop started"
    while(true)
        task = pop_task(processor.conn)
        if !isnothing(task)
            Threads.@spawn proccess_task(processor, task)
        else
            sleep(0.2)
        end
    end
end