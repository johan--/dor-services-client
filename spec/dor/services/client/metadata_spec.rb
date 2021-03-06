# frozen_string_literal: true

require 'active_support/core_ext/time'

RSpec.describe Dor::Services::Client::Metadata do
  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:pid) { 'druid:1234' }

  subject(:client) { described_class.new(connection: connection, version: 'v1', object_identifier: pid) }

  describe '#dublin_core' do
    subject(:response) { client.dublin_core }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:1234/metadata/dublin_core')
        .to_return(status: status, body: body)
    end

    context 'when the object is found' do
      let(:status) { 200 }
      let(:body) { '<dc />' }

      it { is_expected.to eq '<dc />' }
    end

    context 'when the object is not found' do
      let(:status) { 404 }
      let(:body) { '' }

      it { is_expected.to be_nil }
    end

    context 'when there is a server error' do
      let(:status) { [500, 'internal server error'] }
      let(:body) { 'broken' }

      it 'raises an error' do
        expect { response }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                           'internal server error: 500 (broken) for druid:1234')
      end
    end
  end

  describe '#descriptive' do
    subject(:response) { client.descriptive }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:1234/metadata/descriptive')
        .to_return(status: status, body: body)
    end

    context 'when the object is found' do
      let(:status) { 200 }
      let(:body) { '<dc />' }

      it { is_expected.to eq '<dc />' }
    end

    context 'when the object is not found' do
      let(:status) { 404 }
      let(:body) { '' }

      it { is_expected.to be_nil }
    end

    context 'when there is a server error' do
      let(:status) { [500, 'internal server error'] }
      let(:body) { 'broken' }

      it 'raises an error' do
        expect { response }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                           'internal server error: 500 (broken) for druid:1234')
      end
    end
  end

  describe '#legacy_update' do
    context 'for many datastreams' do
      let(:params) do
        {
          descriptive: { updated: Time.find_zone('UTC').parse('2020-01-05'), content: '<descMetadata/>' },
          identity: { updated: Time.find_zone('UTC').parse('2020-01-05'), content: '<identityMetadata/>' }
        }
      end

      before do
        stub_request(:patch, 'https://dor-services.example.com/v1/objects/druid:1234/metadata/legacy')
          .with(
            body: '{"descriptive":{"updated":"2020-01-05T00:00:00.000Z","content":"\\u003cdescMetadata/\\u003e"},' \
                  '"identity":{"updated":"2020-01-05T00:00:00.000Z","content":"\\u003cidentityMetadata/\\u003e"}}',
            headers: { 'Content-Type' => 'application/json' }
          )
          .to_return(status: status)
      end

      context 'when API request succeeds' do
        let(:status) { 204 }

        it 'posts params as json' do
          # byebug
          expect(client.legacy_update(params)).to be_nil
        end
      end

      context 'when API request fails' do
        let(:status) { [404, 'not found'] }

        it 'raises an error' do
          expect { client.legacy_update(params) }.to(
            raise_error(Dor::Services::Client::NotFoundResponse,
                        "not found: 404 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY}) for druid:1234")
          )
        end
      end
    end

    context 'for provenance' do
      let(:params) { { provenance: { updated: Time.find_zone('UTC').parse('2020-01-05'), content: '<provenanceMetadata />' } } }

      before do
        stub_request(:patch, 'https://dor-services.example.com/v1/objects/druid:1234/metadata/legacy')
          .with(
            body: '{"provenance":{"updated":"2020-01-05T00:00:00.000Z","content":"\\u003cprovenanceMetadata /\u003e"}}',
            headers: { 'Content-Type' => 'application/json' }
          )
          .to_return(status: status)
      end

      context 'when API request succeeds' do
        let(:status) { 204 }

        it 'posts params as json' do
          expect(client.legacy_update(params)).to be_nil
        end
      end

      context 'when API request fails' do
        let(:status) { [404, 'not found'] }

        it 'raises an error' do
          expect { client.legacy_update(params) }.to(
            raise_error(Dor::Services::Client::NotFoundResponse,
                        "not found: 404 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY}) for druid:1234")
          )
        end
      end
    end
  end
end
