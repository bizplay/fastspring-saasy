require File.expand_path(File.join(File.dirname(__FILE__), '../lib/fastspring-saasy.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper.rb'))

describe FastSpring::LocalizedStorePricing do
  def valid_http_request
    request = double('request')
    request.stub(:remote_ip).and_return("192.168.1.1")
    request.stub(:env).and_return({ "HTTP_ACCEPT_LANGUAGE" => "nl", "HTTP_X_FORWARDED_FOR" => "192.168.1.2" })
    request
  end

  def invalid_http_request
    double('request')
  end

  def partial_http_request
    request = double('request')
    request.stub(:remote_ip).and_return("192.168.1.1")
    request.stub(:env).and_return({ "HTTP_ACCEPT_LANGUAGE" => "nl" })
    request
  end

  before do
    FastSpring::Account.setup do |config|
      config[:username] = 'admin'
      config[:password] = 'test'
      config[:company] = 'acme'
    end    
  end

  context 'url for localized store pricing' do
    context "with valid http request" do
      subject { FastSpring::LocalizedStorePricing.find(['/standard'], valid_http_request) }
      before(:each) do
        stub_request(:get, "http://sites.fastspring.com/acme/api/price?product_1_path=/standard&user_accept_language=nl&user_remote_addr=192.168.1.1&user_x_forwarded_for=192.168.1.2").
          to_return(:status => 200, :body => "", :headers => {})
      end
    
      it 'returns the path for the company' do
        subject.base_localized_store_pricing_path.should == "/acme/api/price"
      end
    end
    
    context "with invalid http request" do
      subject { FastSpring::LocalizedStorePricing.find(['/standard'], invalid_http_request) }
      before(:each) do
        stub_request(:get, "http://sites.fastspring.com/acme/api/price?product_1_path=/standard&user_accept_language=en&user_remote_addr=127.0.0.1&user_x_forwarded_for=").
          to_return(:status => 200, :body => "", :headers => {})
      end
    
      it 'returns the path for the company' do
        subject.base_localized_store_pricing_path.should == "/acme/api/price"
      end
    end
    
    context "with partial http request" do
      subject { FastSpring::LocalizedStorePricing.find(['/standard'], partial_http_request) }
      before(:each) do
        stub_request(:get, "http://sites.fastspring.com/acme/api/price?product_1_path=/standard&user_accept_language=nl&user_remote_addr=192.168.1.1&user_x_forwarded_for=").
          to_return(:status => 200, :body => "", :headers => {})
      end

      it 'returns the path for the company' do
        subject.base_localized_store_pricing_path.should == "/acme/api/price"
      end
    end
  end
  
  context "parsed response for 1 product" do
    subject { FastSpring::LocalizedStorePricing.find(['/standard'], valid_http_request) }
    before(:each) do
      stub_request(:get, "http://sites.fastspring.com/acme/api/price?product_1_path=/standard&user_accept_language=nl&user_remote_addr=192.168.1.1&user_x_forwarded_for=192.168.1.2").
        to_return(stub_http_response_with('basic_localized_store_pricing.txt'))
    end
  
    it 'returns "US" as the user country' do
      subject.user_country.should == "US"
    end
  
    it 'returns "en" as the user language' do
      subject.user_language.should == "en"
    end
    
    it 'returns "USD" as the user currency' do
      subject.user_currency.should == "USD"
    end
    
    it 'returns "1" as the quantity of product 1' do
      subject.product_quantity("/standard").should == "1"
    end
    
    it 'returns "35.00" as unit value of product 1' do
      subject.product_unit_value("/standard").should == "35.00"
    end
    
    it 'returns "USD" as the unit currency of product 1' do
      subject.product_unit_currency("/standard").should == "USD"
    end
    
    it 'returns "$35.00" as the unit display of product 1' do
      subject.product_unit_display("/standard").should == "$35.00"
    end
    
    it 'returns "$35.00" as the unit html of product 1' do
      subject.product_unit_html("/standard").should == "$35.00"
    end
  end
  
  context "localized pricing details specifically for 3 product" do
    subject { FastSpring::LocalizedStorePricing.find(['/basic','/standard','/plus'], valid_http_request) }
    before(:each) do
      stub_request(:get, "http://sites.fastspring.com/acme/api/price?product_1_path=/basic&product_2_path=/standard&product_3_path=/plus&user_accept_language=nl&user_remote_addr=192.168.1.1&user_x_forwarded_for=192.168.1.2").
        to_return(stub_http_response_with('basic_localized_store_pricing_with_3_products.txt'))
    end
    
    it 'it sends "/basic" as the product_1_path' do
      subject.query[:product_1_path].should == "/basic"
    end
  
    it 'it sends "/standard" as the product_2_path' do
      subject.query[:product_2_path].should == "/standard"
    end
  
    it 'it sends "/plus" as the product_3_path' do
      subject.query[:product_3_path].should == "/plus"
    end
  
    it 'returns "US" as the user country' do
      subject.user_country.should == "US"
    end
  
    it 'returns "en" as the user language' do
      subject.user_language.should == "en"
    end
    
    it 'returns "USD" as the user currency' do
      subject.user_currency.should == "USD"
    end
    
    it 'returns "$19.00" as the unit display of product 1' do
      subject.product_unit_display("/basic").should == "$19.00"
    end
    
    it 'returns "$35.00" as the unit display of product 2' do
      subject.product_unit_display("/standard").should == "$35.00"
    end
    
    it 'returns "$59.00" as the unit display of product 3' do
      subject.product_unit_display("/plus").should == "$59.00"
    end
  end

  # describe "#parse_response" do
  #   before(:each) do
  #     @response = double("Stubbed response")
  #     @response.stub(:parsed_response).and_return(
  #       {"user_country"=>"NL",
  #        "user_language"=>"nl",
  #        "user_currency"=>"EUR",
  #        "product_1_name"=>"Basic Regular | Annually",
  #        "product_1_path"=>"/basic_a",
  #        "product_1_quantity"=>"1",
  #        "product_1_first_currency"=>"EUR",
  #        "product_1_first_display"=>"€ 0,00",
  #        "product_1_first_html"=>"&euro; 0,00",
  #        "product_1_first_value"=>"0.0",
  #        "product_1_unit_currency"=>"EUR",
  #        "product_1_unit_display"=>"€ 150,00",
  #        "product_1_unit_html"=>"&euro; 150,00",
  #        "product_1_unit_value"=>"150.0",
  #        "product_2_name"=>"Standard Regular | Annually",
  #        "product_2_path"=>"/standard_a",
  #        "product_2_quantity"=>"1",
  #        "product_2_first_currency"=>"EUR",
  #        "product_2_first_display"=>"€ 0,00",
  #        "product_2_first_html"=>"&euro; 0,00",
  #        "product_2_first_value"=>"0.0",
  #        "product_2_unit_currency"=>"EUR",
  #        "product_2_unit_display"=>"€ 228,00",
  #        "product_2_unit_html"=>"&euro; 228,00",
  #        "product_2_unit_value"=>"228.0",
  #        "product_3_name"=>"Max Regular | Annually",
  #        "product_3_path"=>"/max_a",
  #        "product_3_quantity"=>"1",
  #        "product_3_first_currency"=>"EUR",
  #        "product_3_first_display"=>"€ 0,00",
  #        "product_3_first_html"=>"&euro; 0,00",
  #        "product_3_first_value"=>"0.0",
  #        "product_3_unit_currency"=>"EUR",
  #        "product_3_unit_display"=>"€ 708,00",
  #        "product_3_unit_html"=>"&euro; 708,00",
  #        "product_3_unit_value"=>"708.0",
  #        "product_4_name"=>"Basic Enterprise | Annually",
  #        "product_4_path"=>"/basic_ent_a",
  #        "product_4_quantity"=>"1",
  #        "product_4_first_currency"=>"EUR",
  #        "product_4_first_display"=>"€ 0,00",
  #        "product_4_first_html"=>"&euro; 0,00",
  #        "product_4_first_value"=>"0.0",
  #        "product_4_unit_currency"=>"EUR",
  #        "product_4_unit_display"=>"€ 150,00",
  #        "product_4_unit_html"=>"&euro; 150,00",
  #        "product_4_unit_value"=>"150.0",
  #        "product_5_name"=>"Standard Enterprise | Annually",
  #        "product_5_path"=>"/standard_ent_a",
  #        "product_5_quantity"=>"1",
  #        "product_5_first_currency"=>"EUR",
  #        "product_5_first_display"=>"€ 0,00",
  #        "product_5_first_html"=>"&euro; 0,00",
  #        "product_5_first_value"=>"0.0",
  #        "product_5_unit_currency"=>"EUR",
  #        "product_5_unit_display"=>"€ 228,00",
  #        "product_5_unit_html"=>"&euro; 228,00",
  #        "product_5_unit_value"=>"228.0",
  #        "product_6_name"=>"Max Enterprise | Annually",
  #        "product_6_path"=>"/max_ent_a",
  #        "product_6_quantity"=>"1",
  #        "product_6_first_currency"=>"EUR",
  #        "product_6_first_display"=>"€ 0,00",
  #        "product_6_first_html"=>"&euro; 0,00",
  #        "product_6_first_value"=>"0.0",
  #        "product_6_unit_currency"=>"EUR",
  #        "product_6_unit_display"=>"€ 708,00",
  #        "product_6_unit_html"=>"&euro; 708,00",
  #        "product_6_unit_value"=>"708.0",
  #        "product_7_name"=>"Basic Regular | Monthly",
  #        "product_7_path"=>"/basic_m",
  #        "product_7_quantity"=>"1",
  #        "product_7_first_currency"=>"EUR",
  #        "product_7_first_display"=>"€ 0,00",
  #        "product_7_first_html"=>"&euro; 0,00",
  #        "product_7_first_value"=>"0.0",
  #        "product_7_unit_currency"=>"EUR",
  #        "product_7_unit_display"=>"€ 15,00",
  #        "product_7_unit_html"=>"&euro; 15,00",
  #        "product_7_unit_value"=>"15.0",
  #        "product_8_name"=>"Standard Regular | Monthly",
  #        "product_8_path"=>"/standard_m",
  #        "product_8_quantity"=>"1",
  #        "product_8_first_currency"=>"EUR",
  #        "product_8_first_display"=>"€ 0,00",
  #        "product_8_first_html"=>"&euro; 0,00",
  #        "product_8_first_value"=>"0.0",
  #        "product_8_unit_currency"=>"EUR",
  #        "product_8_unit_display"=>"€ 22,50",
  #        "product_8_unit_html"=>"&euro; 22,50",
  #        "product_8_unit_value"=>"22.5",
  #        "product_9_name"=>"Max Regular | Monthly",
  #        "product_9_path"=>"/max_m",
  #        "product_9_quantity"=>"1",
  #        "product_9_first_currency"=>"EUR",
  #        "product_9_first_display"=>"€ 0,00",
  #        "product_9_first_html"=>"&euro; 0,00",
  #        "product_9_first_value"=>"0.0",
  #        "product_9_unit_currency"=>"EUR",
  #        "product_9_unit_display"=>"€ 69,00",
  #        "product_9_unit_html"=>"&euro; 69,00",
  #        "product_9_unit_value"=>"69.0",
  #        "product_10_name"=>"Basic Enterprise | Monthly",
  #        "product_10_path"=>"/basic_ent_m",
  #        "product_10_quantity"=>"1",
  #        "product_10_first_currency"=>"EUR",
  #        "product_10_first_display"=>"€ 0,00",
  #        "product_10_first_html"=>"&euro; 0,00",
  #        "product_10_first_value"=>"0.0",
  #        "product_10_unit_currency"=>"EUR",
  #        "product_10_unit_display"=>"€ 15,00",
  #        "product_10_unit_html"=>"&euro; 15,00",
  #        "product_10_unit_value"=>"15.0",
  #        "product_11_name"=>"Standard Enterprise | Monthly",
  #        "product_11_path"=>"/standard_ent_m",
  #        "product_11_quantity"=>"1",
  #        "product_11_first_currency"=>"EUR",
  #        "product_11_first_display"=>"€ 0,00",
  #        "product_11_first_html"=>"&euro; 0,00",
  #        "product_11_first_value"=>"0.0",
  #        "product_11_unit_currency"=>"EUR",
  #        "product_11_unit_display"=>"€ 22,50",
  #        "product_11_unit_html"=>"&euro; 22,50",
  #        "product_11_unit_value"=>"22.5",
  #        "product_12_name"=>"Max Enterprise | Monthly",
  #        "product_12_path"=>"/max_ent_m",
  #        "product_12_quantity"=>"1",
  #        "product_12_first_currency"=>"EUR",
  #        "product_12_first_display"=>"€ 69,00",
  #        "product_12_first_html"=>"&euro; 69,00",
  #        "product_12_first_value"=>"69.0",
  #        "product_12_unit_currency"=>"EUR",
  #        "product_12_unit_display"=>"€ 69,00",
  #        "product_12_unit_html"=>"&euro; 69,00",
  #        "product_12_unit_value"=>"69.0"}      
  #     )
  #     localized_store_pricing = FastSpring::LocalizedStorePricing.new
  #     localized_store_pricing.instance_variable_set(:@response, @response)
  #   end
  #   
  #   it "returns a hash containing key '/basic_a'" do
  #     parsed_response = localized_store_pricing.send(:parse_response)
  #     byebug
  #     parsed_response.should_not be_nil
  #   end
  # end
end
