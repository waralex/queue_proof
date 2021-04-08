using UUIDs
import Redis
import JSON3
using Dash
using DashHtmlComponents
using DashCoreComponents
include("config.jl")
include("misc.jl")

redis_conn = Redis.RedisConnection(host = CONFIG.redis.host, port = CONFIG.redis.port, db = CONFIG.redis.db, password = CONFIG.redis.password)

external_stylesheets = ["https://codepen.io/chriddyp/pen/bWLwgP.css"]
app = dash(external_stylesheets = external_stylesheets)

app.layout = html_div() do
    dcc_store(id="tasks-store", data=(sending_tasks = [],)),
    dcc_interval(
            id="interval",
            interval=500,
            n_intervals=0
    ),
    html_h1("Proof App"),
    html_div() do
        "result:",
        dcc_input(id="result_in", value = "some result", placeholder="any value to return from task"),
        "sleep for (seconds):",
        dcc_input(id="sleep_for", value = 10,  placeholder="seconds to sleep before response"),
        html_button("send task", id = "submit")
    end,
    html_div() do
        html_h2("tasks"),
        html_div(id = "tasks-list")
    end
end

callback!(app,
Output("tasks-store", "data"),
Input("submit", "n_clicks"),
Input("interval", "n_intervals"),
State("result_in", "value"),
State("sleep_for", "value"),
State("tasks-store", "data")
) do n_clicks, n_intervals, result_in, sleep_for, data

    isempty(callback_context().triggered) && return data
    is_submit = callback_context().triggered[1].prop_id == "submit.n_clicks"
    if is_submit
        new_task = (
                task_id = string(uuid4()),
                sleep_for = sleep_for isa AbstractString ? parse(Int64,sleep_for) : sleep_for,
                expected_result = result_in,
                result = nothing,
                started = time_ns(),
                ended = nothing
        )
        redis_push_task(new_task)
        push!(data.sending_tasks, new_task)
    else
        for (i, task) in enumerate(data.sending_tasks)
            !isnothing(task.ended) && continue

            result = redis_check_result(task)
            if !isnothing(result)
                data.sending_tasks[i] = merge(task, (result = result, ended = time_ns()))
            end
        end
    end
    return data
end

callback!(app,
Output("tasks-list", "children"),
Input("interval", "n_intervals"),
State("tasks-store", "data")
) do intervals, data
    rows = [
        html_tr() do
            html_th("task_id"),
            html_th("sleep for"),
            html_th("elapsed time"),
            html_th("expected result"),
            html_th("real result")
        end
    ]
    for task in data.sending_tasks
        last_time = isnothing(task.ended) ? time_ns() : task.ended
        elapsed = (last_time - task.started) / 1e9
        push!(rows,
            html_tr() do
                html_th(task.task_id, style = (color = isnothing(task.ended) ? "black" : "green",)),
                html_td(task.sleep_for),
                html_td(elapsed),
                html_td(task.expected_result),
                html_td(isnothing(task.result) ? "incomplete yet" : task.result)
            end
        )
    end
    return html_table(rows)
end

run_server(app, "0.0.0.0", CONFIG.port, debug = true)