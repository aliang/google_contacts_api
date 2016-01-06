class MockOAuth2Error < StandardError
  attr_accessor :response
  
  def initialize(response)
    @response = response
  end
end

describe GoogleContactsApi::Api do
  describe '#get' do
    context 'when all parameters are correct' do
      before do
        @oauth = double("oauth")
        allow(@oauth).to receive(:get).and_return("get response")
        @api = GoogleContactsApi::Api.new(@oauth)
      end

      context 'when version is not specified' do
        it 'performs a get request using oauth returning json with version 3' do
          expect(@oauth).to receive(:request).with(:get,
            GoogleContactsApi::Api::BASE_URL + "any_url?alt=json&param=param&v=3",
            headers: { "header" => "header" }).and_return("get response")

          expect(@api.get("any_url",
                          {"param" => "param"},
                          {"header" => "header"})).to eq("get response")
        end
      end

      context 'when version is specified' do
        it 'performs a get request using oauth with the version specified' do
          expect(@oauth).to receive(:request).with(:get,
            GoogleContactsApi::Api::BASE_URL + "any_url?alt=json&param=param&v=2",
            headers: {"header" => "header"}).and_return("get response")

          expect(@api.get("any_url",
            {"param" => "param", "v" => "2"},
            {"header" => "header"})).to eq("get response")
        end
      end
    end

    context 'when OAuth 1.0 returns unauthorized' do
      before do
        @oauth = double("oauth")
        allow(@oauth).to receive(:request).and_return(Net::HTTPUnauthorized.new("1.1", 401, "You're not authorized"))
        @api = GoogleContactsApi::Api.new(@oauth)
      end

      it 'raises UnauthorizedError' do
        expect { @api.get("any url",
          {"param" => "param"},
          {"header" => "header"}) }.to raise_error(GoogleContactsApi::UnauthorizedError)
      end
    end

    context 'when OAuth 2.0 returns unauthorized' do
      before do
        @oauth = double("oauth")
        allow(@oauth).to receive(:request).and_raise(MockOAuth2Error.new(OpenStruct.new(status: 401)))
        @api = GoogleContactsApi::Api.new(@oauth)
      end

      it 'raises UnauthorizedError' do
        expect { @api.get("any url",
          {"param" => "param"},
          {"header" => "header"}) }.to raise_error(GoogleContactsApi::UnauthorizedError)
      end
    end
  end

  describe "#parse_response_code" do
    before(:all) do
      @Oauth = Struct.new(:code)
      @Oauth2 = Struct.new(:status)
    end

    it 'parses oauth gem response' do
      expect(GoogleContactsApi::Api.parse_response_code(@Oauth.new("401"))).to eq(401)
    end

    it 'parses oauth2 gem response' do
      expect(GoogleContactsApi::Api.parse_response_code(@Oauth2.new(401))).to eq(401)
    end
  end

  describe "non-get http verbs" do
    before do
      @oauth = double("oauth")
      @api = GoogleContactsApi::Api.new(@oauth)
    end

    describe "#post" do
      it "performs a post request using oauth" do
        expect(@oauth).to receive(:request)
          .with(:post, GoogleContactsApi::Api::BASE_URL + "any_url?alt=json&param=param&v=3",
        body: 'body', headers: {"header" => "header"})
          .and_return('response')

        expect(@api.post("any_url", 'body', {"param" => "param"}, {"header" => "header"}))
          .to eq("response")
      end
    end

    describe "#put" do
      it "performs a put request using oauth" do
        expect(@oauth).to receive(:request)
          .with(:put, GoogleContactsApi::Api::BASE_URL + "any_url?alt=json&param=param&v=3",
        body: 'body', headers: {"header" => "header"})
          .and_return('response')

        expect(@api.put("any_url", 'body', {"param" => "param"}, {"header" => "header"}))
          .to eq("response")
      end
    end

    def expect_oauth_request_with_body(method)
      expect(@oauth).to receive(:request)
        .with(method, GoogleContactsApi::Api::BASE_URL + "any_url?alt=json&param=param&v=3",
              body: "body", headers: {"header" => "header"})
        .and_return('response')

      expect(@api.public_send(method, "any_url", "body", {"param" => "param"},
                              {"header" => "header"}))
        .to eq("response")
    end

    describe "#delete" do
      it "perform a delete request using oauth" do
        expect(@oauth).to receive(:request)
          .with(:delete, GoogleContactsApi::Api::BASE_URL + "any_url?alt=json&param=param&v=3",
        headers: {"header" => "header"})
          .and_return('response')

        # The delete method does not take the body argument that put and post do.
        expect(@api.delete("any_url", {"param" => "param"}, {"header" => "header"}))
          .to eq("response")
      end
    end
  end
end
