const CONFIG = (
    port = 8000,
    redis = (
        host = "0.0.0.0",
        port = 6379,
        db = 0,
        password = ""
    ),
    queue = (
        key = "test_queue",
    )
)