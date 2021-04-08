
function connect(config)
    return Redis.RedisConnection(host = config.redis.host, port = config.redis.port, db = config.redis.db, password = config.redis.password)
end
