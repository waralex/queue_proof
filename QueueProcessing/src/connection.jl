struct TaskConnection
    conn ::Redis.RedisConnection
    queue_key ::String
    lock ::ReentrantLock
    function TaskConnection(config)
        return new(
            Redis.RedisConnection(host = config.redis.host,
                 port = config.redis.port,
                 db = config.redis.db,
                 password = config.redis.password
                ),
            config.queue.key,
            ReentrantLock()
        )
    end
end

function pop_task(conn::TaskConnection)
    json = lock(conn.lock) do
        Redis.lpop(conn.conn, conn.queue_key)
    end
    isnothing(json) && return nothing
    task = JSON3.read(json)
    !haskey(task,"task_id") && return nothing
    return task
end

function set_result(conn::TaskConnection, task_id, result)
    lock(conn.lock) do
        Redis.set(conn.conn, task_id, result)
        Redis.expire(conn.conn, task_id, 60)
    end
end