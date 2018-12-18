# frozen_string_literal: true

require 'dor/services/client/version'
require 'singleton'
require 'faraday'
require 'active_support/core_ext/hash/indifferent_access'

module Dor
  module Services
    class Client
      class Error < StandardError; end

      include Singleton

      def self.configure(url:)
        instance.url = url
      end

      # Creates a new object in DOR
      # @return [HashWithIndifferentAccess] the response, which includes a :pid
      def self.register(params:)
        instance.register(params: params)
      end

      # @param [String] object the identifier for the object
      # @param [String] filename the name of the file to retrieve
      # @return [String] the file contents from the workspace
      def self.retrieve_file(object:, filename:)
        instance.retrieve_file(object: object, filename: filename)
      end

      # @param [String] object the identifier for the object
      # @return [Array<String>] the list of filenames in the workspace
      def self.list_files(object:)
        instance.list_files(object: object)
      end

      attr_writer :url

      def url
        @url || raise(Error, 'url has not yet been configured')
      end

      def register(params:)
        resp = connection.post do |req|
          req.url 'v1/objects'
          req.headers['Content-Type'] = 'application/json'
          req.headers['Accept'] = 'application/json' # asking the service to return JSON (else it'll be plain text)
          req.body = params.to_json
        end
        raise "#{resp.reason_phrase}: #{resp.status} (#{resp.body})" unless resp.success?

        JSON.parse(resp.body).with_indifferent_access
      end

      def retrieve_file(object:, filename:)
        resp = connection.get do |req|
          req.url "v1/objects/#{object}/contents/#{filename}"
        end
        return unless resp.success?

        resp.body
      end

      def list_files(object:)
        resp = connection.get do |req|
          req.url "v1/objects/#{object}/contents"
        end
        return [] unless resp.success?

        json = JSON.parse(resp.body)
        json['items'].map { |item| item['name'] }
      end

      private

      def connection
        @connection ||= Faraday.new(url)
      end
    end
  end
end
