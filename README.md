# JumpTickets

## Set up .env File
Copy and paste the contents of `.env.template` into a new file called `.env` and make sure to run `source .env` in the command line after modifying values of this file.

## Set up Intercom

- Create an [Intercom](https://app.intercom.com/admins/sign_up) account and sign up for a free trial ( no credit card required )
- Visit Intercom Developer Hub and create an app https://app.intercom.com/a/apps/_/developer-hub
- Click on your app and visit the Authentication page, you should be able to copy a secret from there ![alt text](image.png)
- Paste the Intercom app's access token into the `INTERCOM_SECRET` variable of your `.env` file
- From the Intercom UI ( Not developer hub ) go to Settings > Integrations > Actions > Create a data connector
  ![alt text](image-1.png)
- Keep all defaults for the About section
![Create action - 1](docs/create-action-1.png)
- In the API Connection step's API Request section,set Method to POST and HTTPS URL to `PHX_HOST` + `/api/submit` and include the headers and request body from the related screenshot in the `/docs` folder.
![Create action - 2](docs/create-action-2.png)
  - If you want to hook up the intercom request to your local machine on dev before you make an actual deployment, you can use some reverse tunnel service like ngrok or cloudflare tunnels, but you could also just call the controller directly from iex
- In the Test response, you can select Example request and slightly modify the body to pass to the next step
- Leave defaults for the next 2 steps and click "Set live" (You do not need to enable verification)
- In order for the "Done" ticket notifier to work, you also need to set `INTERCOM_ADMIN_ID`. Feel free to use the helper `JumpTickets.External.Intercom.get_admin_details` to list all the available admins ( either remote attach or simple `iex -S mix phx.server`). Note that you may need to run `source .env` in order for `JumpTickets.External.Intercom.get_admin_details` to use the correct env variable
- To test the integration, go to any Intercom conversation, hover over a message, click on the three dot menu and look for "trigger custom action". Sometimes the list of actions is not hydrated and you might need to type something like "notion" in the searchbox for it to show up

## Set up Anthropic

This project uses Anthropic's Claude-3.5-haiku for deciding between existing tickets
- [Sign up for an Anthropic account](https://www.anthropic.com/api) if you don't have one already. If you do not have one, you will need to pay $5 USD for token credits 
- Set the API key `CLAUDE_SECRET` with your Anthropic API key
- You may use alternative LLM APIs if you wish

## Set up Notion

- [Sign up for a Notion account](https://www.notion.com/)
- Create a new integration at https://www.notion.so/profile/integrations and copy its secret
- Grab the secret key and set `NOTION_SECRET`
- Create a new database on notion, it should have these fields:
  - ![alt text](image-3.png)
  - ![alt text](image-4.png)
  - This one is an ID type, set the prefix to JMP when configuring it ![alt text](image-5.png)
  - ![alt text](image-6.png)
  - ![alt text](image-7.png)
- Here's what it should look like at the end of this process ![alt text](image-8.png)
- Add the integration to the db file by clicking on the three dots on the page and choosing the app you created under Connections. Allow access to this page and child pages when asked
  ![alt text](image-2.png)
- Grab db id and set `NOTION_DB_ID`

## Set up Slack

- [Create a Slack workspace](https://slack.com/) if you do not have one already
- Create slack app at https://api.slack.com/apps and navigate to OAuth and Permissions
- Set the following bot token scopes

  ```
  channels:manage
  channels:read
  channels:write.invites
  chat:write
  users:read
  users:read.email
  ```
- In the OAuth Tokens section, click "Install to [your workspace's name>]"
- Set `SLACK_BOT_TOKEN` with the value generated from the previous step
  ![alt text](docs/slack-bot.png)

## Testing

- Start with iex -S mix phx.server

```elixir
JumpTickets.IntegrationRequest.create_integration_request(%{
  conversation_id: <you can grab this from the intercom conversation, it's the last url part and looks like 215468800369841>,
  conversation_url: conversation_url,
  message_body: message_body
})
```

- Visit localhost:4000 ( the http basic auth creds are set with AUTH_USERNAME and AUTH_PASSWORD )

## Local

- Make sure that `.env` has all of the necessary variables from the following steps and run `source .env`
- Run `mix setup`
- Run `mix phx.server`

## Deploy

In .env ...
- Set `PHX_HOST` to the url the base app is hosted on
- Set `SECRET_KEY_BASE` to the result of `mix phx.gen.secret`
- Set `MIX_ENV` to "prod"
  ```
    $ source .env
    $ mix deps.get
    $ mix assets.deploy
    $ mix release
    $  _build/prod/rel/jump_tickets/bin/jump_tickets start
  ```

## Integration Logic

- You can inspect the running requests with the functions under the IntegrationRequest context ( like JumpTickets.IntegrationRequest.list_integration_requests() )

```elixir
# Sample request for reference
%JumpTickets.IntegrationRequest.Request{
  id: nil,
  intercom_conversation_id: "2",
  intercom_conversation_url: "https://new-test.example.com",
  message_body: "What is happening?",
  status: :completed,
  steps: %{
    check_existing_tickets: %JumpTickets.IntegrationRequest.Step{
      type: :check_existing_tickets,
      status: :completed,
      started_at: ~U[2025-03-16 18:16:13.845786Z],
      completed_at: ~U[2025-03-16 18:16:14.641125Z],
      error: nil,
      result: [
        %JumpTickets.Ticket{
          __meta__: #Ecto.Schema.Metadata<:built, "tickets">,
          id: nil,
          notion_id: "1b8d3c1b-90d3-81ab-abae-f453c9ef24cc",
          notion_url: "https://www.notion.so/Test-Conversation-WhatsApp-Channel-Setup-Demonstration-1b8d3c1b90d381ababaef453c9ef24cc",
          ticket_id: "JMP-29",
          title: "Test Conversation - WhatsApp Channel Setup Demonstration",
          intercom_conversations: "https://test.com",
          summary: nil,
          slack_channel: "https://app.slack.com/client/T08HPMYC8G6/C08J8FYMNQH?entry_point=nav_menu"
        }
      ]
    },
    ai_analysis: %JumpTickets.IntegrationRequest.Step{
      type: :ai_analysis,
      status: :completed,
      started_at: ~U[2025-03-16 18:16:14.641136Z],
      completed_at: ~U[2025-03-16 18:16:21.214706Z],
      error: nil,
      result: {:existing,
       %JumpTickets.Ticket{
         __meta__: #Ecto.Schema.Metadata<:built, "tickets">,
         id: nil,
         notion_id: "1b8d3c1b-90d3-81ab-abae-f453c9ef24cc",
         notion_url: "https://www.notion.so/Test-Conversation-WhatsApp-Channel-Setup-Demonstration-1b8d3c1b90d381ababaef453c9ef24cc",
         ticket_id: "JMP-29",
         title: "Test Conversation - WhatsApp Channel Setup Demonstration",
         intercom_conversations: "https://test.com",
         summary: nil,
         slack_channel: "https://app.slack.com/client/T08HPMYC8G6/C08J8FYMNQH?entry_point=nav_menu"
       }}
    },
    create_or_update_notion_ticket: %JumpTickets.IntegrationRequest.Step{
      type: :create_or_update_notion_ticket,
      status: :completed,
      started_at: ~U[2025-03-16 19:37:43.331492Z],
      completed_at: ~U[2025-03-16 19:37:44.668251Z],
      error: nil,
      result: %JumpTickets.Ticket{
        __meta__: #Ecto.Schema.Metadata<:built, "tickets">,
        id: nil,
        notion_id: "1b8d3c1b-90d3-81ab-abae-f453c9ef24cc",
        notion_url: "https://www.notion.so/Test-Conversation-WhatsApp-Channel-Setup-Demonstration-1b8d3c1b90d381ababaef453c9ef24cc",
        ticket_id: "JMP-29",
        title: "Test Conversation - WhatsApp Channel Setup Demonstration",
        intercom_conversations: "https://new-test.example.com,https://test.com",
        summary: nil,
        slack_channel: "https://app.slack.com/client/T08HPMYC8G6/C08J8FYMNQH?entry_point=nav_menu"
      }
    },
    maybe_create_slack_channel: %JumpTickets.IntegrationRequest.Step{
      type: :maybe_create_slack_channel,
      status: :completed,
      started_at: ~U[2025-03-16 19:37:44.668263Z],
      completed_at: ~U[2025-03-16 19:37:44.668287Z],
      error: nil,
      result: %{
        url: "https://app.slack.com/client/T08HPMYC8G6/C08J8FYMNQH?entry_point=nav_menu",
        channel_id: "C08J8FYMNQH"
      }
    },
    maybe_update_notion_with_slack: %JumpTickets.IntegrationRequest.Step{
      type: :maybe_update_notion_with_slack,
      status: :completed,
      started_at: ~U[2025-03-16 19:37:44.668292Z],
      completed_at: ~U[2025-03-16 19:37:45.421927Z],
      error: nil,
      result: %JumpTickets.Ticket{
        __meta__: #Ecto.Schema.Metadata<:built, "tickets">,
        id: nil,
        notion_id: "1b8d3c1b-90d3-81ab-abae-f453c9ef24cc",
        notion_url: "https://www.notion.so/Test-Conversation-WhatsApp-Channel-Setup-Demonstration-1b8d3c1b90d381ababaef453c9ef24cc",
        ticket_id: "JMP-29",
        title: "Test Conversation - WhatsApp Channel Setup Demonstration",
        intercom_conversations: "https://new-test.example.com,https://test.com",
        summary: nil,
        slack_channel: "https://app.slack.com/client/T08HPMYC8G6/C08J8FYMNQH?entry_point=nav_menu"
      }
    },
    add_intercom_users_to_slack: %JumpTickets.IntegrationRequest.Step{
      type: :add_intercom_users_to_slack,
      status: :completed,
      started_at: ~U[2025-03-16 19:37:45.421939Z],
      completed_at: ~U[2025-03-16 19:37:47.775819Z],
      error: nil,
      result: nil
    }
  },
  created_at: ~U[2025-03-16 18:16:13.845205Z],
  updated_at: ~U[2025-03-16 19:37:47.775832Z],
  context: %{}
}
```
