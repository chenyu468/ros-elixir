# ROS - Elixir

## Example Publisher

```elixir
use ROS.Node

children = [
  node(:"/mynode", [
    publisher(:mypub, "chatter", "std_msgs/String")
  ])
]

Supervisor.start_link(children)

for n <- 1..100 do
  Publisher.publish(:mypub, %StdMsgs.String{data: "This is my #{n}th message!"})
end
```

## Example Subscriber

```elixir
use ROS.Node

callback = fn %StdMsgs.String{data: data} ->
  IO.puts(data)
end

children = [
  node(:"/mynode", [
    subscriber("chatter", "std_msgs/String", callback)
  ])
]

Supervisor.start_link(children)

ROS.spin()
```
