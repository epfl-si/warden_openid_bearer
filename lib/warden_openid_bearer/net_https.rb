# frozen_string_literal: true

require "net/http"

module WardenOpenidBearer
  # Like Net::HTTP, but with TLS and VERIFY_PEER always on.
  class NetHTTPS < Net::HTTP
    def initialize(*things)
      super(*things)
      self.use_ssl = true
      self.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end

    def peer_cert=(peer_cert)
      self.verify_hostname = false
      self.verify_callback = lambda do |preverify_ok, cert_store|
        end_cert_der = cert_store.chain[0].to_der
        return preverify_ok unless end_cert_der == cert_store.current_cert.to_der

        return end_cert_der == peer_cert.to_der
      end
    end

    def self.get_response(uri, peer_cert = nil)
      https = new(uri.hostname, uri.port)
      https.peer_cert = peer_cert if peer_cert

      req = Net::HTTP::Get.new(uri)
      https.start do |https|
        https.request(req)
      end
    end
  end
end
