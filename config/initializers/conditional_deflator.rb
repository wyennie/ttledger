# config/application.rb or an initializer
class ConditionalDeflater
  def initialize(app)
    @app = app
  end

  def call(env)
    # Skip Rack::Deflater for specific paths
    if env["PATH_INFO"].include?("/chat_respses")
      @app.call(env)
    else
      Rack::Deflater.new(@app).call(env)
    end
  end
end
