defmodule ROS.SlaveApi do
  use GenServer
  use Private

  # unclear as of yet if this is useful... doubtful
  @default_state %{remote_publishers: %{}}

  @spec start_link(Keyword.t()) :: :ok
  def start_link(opts) do
    name = Keyword.fetch!(opts, :node_name)

    GenServer.start_link(__MODULE__, opts, name: from_node_name(name))
  end

  @impl GenServer
  def init(node_info) do
    IO.inspect({:ok, consume(node_info)})
  end

  @spec call(atom(), String.t(), [any()]) :: [any()]
  def call(name, method, args), do: GenServer.call(name, {method, args})

  @doc "Gets the master URI pointed to by the env var ROS MASTER URI"
  @spec master_uri() :: String.t()
  def master_uri, do: System.get_env("ROS_MASTER_URI")

  @doc "Append the node name with \"_api_server\""
  @spec from_node_name(atom()) :: atom()
  def from_node_name(name) do
    String.to_atom(Atom.to_string(name) <> "_api_server")
  end

  @impl GenServer
  def handle_call({"getMasterUri", [_caller_id]}, _from, state) do
    {:reply, [1, "ROS Master Uri", master_uri()], state}
  end

  def handle_call({"publisherUpdate", ["/master", topic, publisher_list]}, _from, %{node_name: node_name, local_subs: all_subs} = state) do
    state = put_in(state[:remote_publishers], topic, publisher_list)

    case Map.fetch(all_subs, topic) do
      :error ->
        {:reply, [1, "go fish. i don't have those subs.", 1], state}

      {:ok, _subs} ->
        #sub_names = Enum.map(subs, &Keyword.get(&1, :name))

        # for sub <- sub_names, pub <- publisher_list do
        for pub <- publisher_list do
          ROS.Subscriber.request(node_name, topic, pub, [["TCPROS"]])
        end
    end

    {:reply, [1, "publisher list for #{topic} updated.", 0], state}
  end

  def handle_call(
        {"requestTopic", [_caller_id, topic, [["TCPROS"]]]},
        _from,
        %{local_pubs: pubs, uri: {ip, _}} = state
      ) do
    port =
      pubs
      |> Enum.find_value(fn {pub_topic, opts} ->
        pub_topic == topic && opts[:name]
      end)
      |> ROS.Publisher.connect("TCPROS")

    {:reply, [1, "ready on http://#{ip}:#{port}", ["TCPROS", ip, port]], state}
  end

  def handle_call({fun, _params}, _from, state) do
    {:relply, [-1, "method not found", fun], state}
  end

  private do
    @spec consume(Keyword.t()) :: %{}
    defp consume(opts) do
      {children, opts} = Keyword.pop(opts, :children, [])
      opts_map = Enum.into(opts, @default_state)

      children
      |> Enum.reduce(%{}, &add_to_map/2)
      |> Map.merge(opts_map)
    end

    defp add_to_map({ROS.Publisher, opts}, acc) do
      put_in(acc[:local_pubs], %{opts[:topic] => opts})
    end
    defp add_to_map({ROS.Subscriber, opts}, acc) do
      new_sub_list =
        case Map.fetch(acc[:local_subs], opts[:topic]) do
          {:ok, sub_list} when is_list(sub_list) -> [opts | sub_list]

          :error -> [opts]
        end

      Map.put(acc, opts[:topic], new_sub_list)
    end
    defp add_to_map(_, acc), do: acc

    @spec translate_publisher(String.t()) :: {{integer(), integer(), integer(), integer()}, integer()}
    defp translate_publisher("http://" <> rest) do
      {ip_txt, port_txt} = String.split(rest, ":")

      {List.to_tuple(String.split(ip_txt)), String.to_integer(port_txt)}
    end
  end
end
