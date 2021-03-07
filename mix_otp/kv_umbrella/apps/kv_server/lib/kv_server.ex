defmodule KVServer do
  @moduledoc """
  Documentation for `KVServer`.
  """
  require Logger

  def accept(port) do
    # The options below mean:
    #
    # 1. `:binary` - receives data as binaries (instead of lists)
    # 2. `packet: :line` - receives data line by line
    # 3. `active: false` - blocks on `:gen_tcp.recv/2` until data is available
    # 4. `reuseaddr: true` - allows us to reuse the address if the listener crashes
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    # serve(client)
    # spawns other processes to server requests
    {:ok, pid} = Task.Supervisor.start_child(KVServer.TaskSupervisor, fn -> serve(client) end)
    # delete child process as controlling process of socket
    # so socket is not tie to acceptor process which accept them
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    # old doctest
    # socket
    # |> read_line()
    # |> write_line(socket)

    # msg =
    #   case read_line(socket) do
    #     {:ok, data} ->
    #       case KVServer.Command.parse(data) do
    #         {:ok, command} ->
    #           KVServer.Command.run(command)

    #         {:error, _} = err ->
    #           err
    #       end

    #     {:error, _} = err ->
    #       err
    #   end

    msg =
      with {:ok, data} <- read_line(socket),
           {:ok, command} <- KVServer.Command.parse(data),
           do: KVServer.Command.run(command)

    write_line(socket, msg)
    serve(socket)
  end

  defp read_line(socket) do
    # old doctest
    # {:ok, data} = :gen_tcp.recv(socket, 0)
    # data
    :gen_tcp.recv(socket, 0)
  end

  # doctest part
  # defp write_line(line, socket) do
  #   :gen_tcp.send(socket, line)
  # end

  defp write_line(socket, {:ok, text}) do
    :gen_tcp.send(socket, text)
  end

  defp write_line(socket, {:error, :unknown_command}) do
    # Known error; write to the client
    :gen_tcp.send(socket, "UNKNOWN COMMAND\r\n")
  end

  defp write_line(socket, {:error, :not_found}) do
    # When can't find bucket by id
    :gen_tcp.send(socket, "NOT FOUND\r\n")
  end

  # error when one of cliens close connection. E.g:
  defp write_line(_socket, {:error, :closed}) do
    # The connection was closed, exit politely
    IO.puts("bye bye!")
    exit(:shutdown)
  end

  defp write_line(socket, {:error, error}) do
    # Unknown error; write to the client and exit
    :gen_tcp.send(socket, "ERROR\r\n")
    exit(error)
  end
end
