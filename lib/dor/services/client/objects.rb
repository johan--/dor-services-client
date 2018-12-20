# frozen_string_literal: true

require 'nokogiri'

module Dor
  module Services
    class Client
      # API calls that are about a repository object
      class Objects < VersionedService
        # Creates a new object in DOR
        # @return [HashWithIndifferentAccess] the response, which includes a :pid
        def register(params:)
          json = register_response(params: params)
          JSON.parse(json).with_indifferent_access
        end

        # Publish a new object
        # @param object [String] the pid for the object
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [boolean] true on success
        def publish(object:)
          resp = connection.post do |req|
            req.url "#{version}/objects/#{object}/publish"
          end
          raise UnexpectedResponse, "#{resp.reason_phrase}: #{resp.status} (#{resp.body})" unless resp.success?

          true
        end

        # Gets the current version number for the object
        # @param object [String] the pid for the object
        # @raise [UnexpectedResponse] when the response is not successful.
        # @raise [MalformedResponse] when the response is not parseable.
        # @return [Integer] the current version
        def current_version(object:)
          xml = current_version_response(object: object)
          begin
            doc = Nokogiri::XML xml
            raise if doc.root.name != 'currentVersion'

            return Integer(doc.text)
          rescue StandardError
            raise MalformedResponse, "Unable to parse XML from current_version API call: #{xml}"
          end
        end

        private

        # make the registration request to the server
        # @raises [UnexpectedResponse] on an unsuccessful response from the server
        # @returns [String] the raw JSON from the server
        def register_response(params:)
          resp = connection.post do |req|
            req.url "#{version}/objects"
            req.headers['Content-Type'] = 'application/json'
            # asking the service to return JSON (else it'll be plain text)
            req.headers['Accept'] = 'application/json'
            req.body = params.to_json
          end
          return resp.body if resp.success?

          raise UnexpectedResponse, "#{resp.reason_phrase}: #{resp.status} (#{resp.body})"
        end

        # make the request to the server for the currentVersion xml
        # @raises [UnexpectedResponse] on an unsuccessful response from the server
        # @returns [String] the raw xml from the server
        def current_version_response(object:)
          resp = connection.get do |req|
            req.url current_version_path(object: object)
          end
          return resp.body if resp.success?

          raise UnexpectedResponse, "#{resp.reason_phrase}: #{resp.status} (#{resp.body}) for #{object}"
        end

        def current_version_path(object:)
          "#{version}/sdr/objects/#{object}/current_version"
        end
      end
    end
  end
end
