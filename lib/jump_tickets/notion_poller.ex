defmodule JumpTickets.NotionPoller do
  use GenServer

  # every 5 seconds
  @poll_interval :timer.seconds(5)

  alias JumpTickets.External.Notion
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    schedule_poll()
    {:ok, state}
  end

  defp schedule_poll do
    Process.send_after(self(), :poll_notion, @poll_interval)
  end

  @impl true
  def handle_info(:poll_notion, state) do
    check_notion_updates(state)
    schedule_poll()
    {:noreply, state}
  end

  defp check_notion_updates(last_state) do
    with {:ok, tickets} <- Notion.query_db() do
      Enum.each(tickets, fn %JumpTickets.Ticket{} = ticket ->
        previous = Map.get(last_state, ticket.notion_id, %{done: false})
        now_done = ticket.done
        was_done = previous.done

        if now_done && !was_done do
          send_slack_notification(ticket)
        else
          Logger.info("Message was already sent!")
        end
      end)

      # Return new state map by notion_id => %{done: bool}
      new_state = Map.new(tickets, fn t -> {t.notion_id, %{done: t.done}} end)
      new_state
    else
      {:error, err} ->
        IO.inspect(err, label: "Failed to poll Notion")
        last_state
    end
  end

  defp send_slack_notification(ticket) do
    message = """
    :white_check_mark: *#{ticket.title}* was marked as _Done_.
    :link: #{ticket.notion_url}
    """

    case ticket.slack_channel do
      nil ->
        Logger.warn("No Slack channel configured for ticket #{ticket.ticket_id}")
        :noop

      channel ->
        {:ok, channel_id} = extract_channel_id(channel)
        JumpTickets.External.Slack.post_message(channel_id, message)
    end
  end

  defp extract_channel_id(url) when is_binary(url) do
    case Regex.run(~r|/client/[A-Z0-9]+/([A-Z0-9]+)|, url) do
      [_, channel_id] -> {:ok, channel_id}
      _ -> {:error, "Channel ID not found in URL"}
    end
  end
end
