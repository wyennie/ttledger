class ChatService
  def initialize
    @client = self.client
  end

  def generate_response(prompts, user_input)
    messages = prompts.map { |prompt| { role: "user", content: prompt } }
    messages << { role: "user", content: user_input }

    @client.chat(
      parameters: {
        model:    "gpt-4o-mini-2024-07-18",
        messages: messages,
        stream:   proc do |chunk|
          yield chunk if block_given? # Pass chunk back to the caller
        end
      }
    )
  end

  def add_page_context(page_slug)
    page = Page.find_by(slug: page_slug)
    return "Page not found." unless page

    body = ""
    if page.body.present?
      body = page.body
              .gsub(/<\/ul>/, "")
              .gsub(/<ul>/, "\n")
              .gsub(/<\/li>/, "")
              .gsub(/<li>/, "\n- ")
              .gsub(/<\/?p>|<br\s*\/?>/, "\n")
              .gsub(/\n+/, "\n")
    end

    "Given the following information:\n#{body}\nAnswer the following:\n"
  end

  private

    def client
      OpenAI::Client.new(
        access_token: Rails.application.credentials.open_ai_api_key,
        log_errors: true
      )
    end

    def models
      [
        "gpt-4o-audio-preview-2024-10-01",
        "gpt-4o-mini-audio-preview",
        "gpt-4o-realtime-preview-2024-10-01",
        "gpt-4o-mini-audio-preview-2024-12-17",
        "gpt-4o-mini-realtime-preview",
        "dall-e-2",
        "gpt-4-1106-preview",
        "gpt-4o-realtime-preview-2024-12-17",
        "gpt-3.5-turbo",
        "gpt-3.5-turbo-0125",
        "gpt-3.5-turbo-instruct",
        "babbage-002",
        "whisper-1",
        "dall-e-3",
        "gpt-3.5-turbo-16k",
        "omni-moderation-latest",
        "o1-preview-2024-09-12",
        "omni-moderation-2024-09-26",
        "tts-1-hd-1106",
        "o1-preview",
        "gpt-4",
        "gpt-4-0613",
        "chatgpt-4o-latest",
        "gpt-4-0125-preview",
        "tts-1-hd",
        "davinci-002",
        "gpt-4o-mini",
        "text-embedding-ada-002",
        "gpt-3.5-turbo-1106",
        "gpt-4o-audio-preview",
        "gpt-4-turbo-2024-04-09",
        "gpt-4-turbo",
        "tts-1",
        "tts-1-1106",
        "gpt-3.5-turbo-instruct-0914",
        "gpt-4-turbo-preview",
        "gpt-4o-mini-realtime-preview-2024-12-17",
        "gpt-4o-mini-2024-07-18",
        "gpt-4o-2024-05-13",
        "text-embedding-3-small",
        "gpt-4o-2024-11-20",
        "text-embedding-3-large",
        "o1-mini",
        "gpt-4o-2024-08-06",
        "o1-mini-2024-09-12",
        "gpt-4o",
        "gpt-4o-audio-preview-2024-12-17",
        "gpt-4o-realtime-preview"
      ]
    end
end
