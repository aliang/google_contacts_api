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
          expect(@oauth).to receive(:get).with(
            GoogleContactsApi::Api::BASE_URL + "any_url?alt=json&param=param&v=3", {"header" => "header"})

          expect(@api.get("any_url",
            {"param" => "param"},
            {"header" => "header"})).to eq("get response")
        end
      end

      context 'when version is specified' do
        it 'performs a get request using oauth with the version specified' do
          expect(@oauth).to receive(:get).with(
            GoogleContactsApi::Api::BASE_URL + "any_url?alt=json&param=param&v=2", {"header" => "header"})

          expect(@api.get("any_url",
            {"param" => "param", "v" => "2"},
            {"header" => "header"})).to eq("get response")
        end
      end
    end

    context 'when OAuth 1.0 returns unauthorized' do
      before do
        @oauth = double("oauth")
        allow(@oauth).to receive(:get).and_return(Net::HTTPUnauthorized.new("1.1", 401, "You're not authorized"))
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
        allow(@oauth).to receive(:get).and_raise(MockOAuth2Error.new(OpenStruct.new(status: 401)))
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

  pending "should perform a post request using oauth"
  pending "should perform a put request using oauth"
  pending "should perform a delete request using oauth"
end
