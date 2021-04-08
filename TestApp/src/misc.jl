redis_connect() =
    Redis.RedisConnection(host = CONFIG.redis.host,
         port = CONFIG.redis.port,
         db = CONFIG.redis.db,
         password = CONFIG.redis.password
         )

function redis_push_task(task)
        redis_request = (
            task_id = task.task_id,
            sleep_for = task.sleep_for,
            expected_result = task.expected_result
        )
        conn = redis_connect()
        Redis.rpush(
            conn,
            CONFIG.queue.key,
            JSON3.write(redis_request)
        )
        Redis.disconnect(conn)
end

function redis_check_result(task)
    conn = redis_connect()
    result = Redis.get(conn, task.task_id)
    !isnothing(result) && Redis.del(conn, task.task_id)
    Redis.disconnect(conn)
    return result
end