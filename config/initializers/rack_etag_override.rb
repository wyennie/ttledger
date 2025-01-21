module Rack
  class ETag
    def skip_caching?(headers)
      headers.key?(ETAG_STRING) || headers[TRANSFER_ENCODING] == "chunked" || headers.key?('Last-Modified')
    end
  end
end
