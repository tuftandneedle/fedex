require 'spec_helper'

module Fedex
  describe Shipment do
    let (:fedex) { Shipment.new(fedex_credentials) }
    let(:shipper) do
      { :name => "Sender", :company => "Company", :phone_number => "555-555-5555", :address => "Main Street", :city => "Harrison", :state => "AR", :postal_code => "72601", :country_code => "US" }
    end
    let(:recipient) do
      { :name => "Recipient", :company => "Company", :phone_number => "555-555-5555", :address => "Main Street", :city => "Frankin Park", :state => "IL", :postal_code => "60131", :country_code => "US", :residential => true }
    end
    let(:packages) do
      [
        {
          :weight => {:units => "LB", :value => 2},
          :dimensions => {:length => 10, :width => 5, :height => 4, :units => "IN" }
        }
      ]
    end
    let(:shipping_options) do
      { :packaging_type => "YOUR_PACKAGING", :drop_off_type => "REGULAR_PICKUP" }
    end
    let(:payment_options) do
      { :type => "SENDER", :account_number => fedex_credentials[:account_number], :name => "Sender", :company => "Company", :phone_number => "555-555-5555", :country_code => "US" }
    end
    let(:filename) do
      require 'tmpdir'
      File.join(Dir.tmpdir, "label#{rand(15000)}.pdf")
    end
    let(:shipment_tracking_number) do
      fedex.ship({ :shipper => shipper,
                   :recipient => recipient,
                   :packages => packages,
                   :service_type => "FEDEX_GROUND",
                   :filename => filename })[:completed_shipment_detail][:completed_package_details][:tracking_ids][:tracking_number]
    end

    context "#delete" do
      context "delete shipment with tracking number", :vcr do
        let(:options) do
          { :tracking_number => shipment_tracking_number }
        end

        it "deletes a shipment" do
          expect{ fedex.delete(options) }.to_not raise_error
        end
      end

      context "raise an error when the tracking number is invalid", :vcr do
        let(:options) do
          { :tracking_number => '111111111' }
        end

        it "raises an error" do
          expect {fedex.delete(options) }.to raise_error(Fedex::RateError, 'Invalid tracking number')
        end
      end
    end
  end
end
