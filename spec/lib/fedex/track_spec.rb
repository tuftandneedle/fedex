require 'spec_helper'

module Fedex
  describe TrackingInformation do
    let(:fedex) { Shipment.new(fedex_credentials) }

    context "shipments with tracking number", :vcr, :focus do
      let(:options) do
        { :package_id             => "122816215025810",
          :package_type           => "TRACKING_NUMBER_OR_DOORTAG",
          :include_detailed_scans => true
        }
      end

      let(:uuid) { fedex.track(options).first.unique_tracking_number }

      it "returns an array of tracking information results" do
        puts fedex.to_yaml
        results = fedex.track(options)
        expect(results).not_to be_empty
      end

      it "returns events with tracking information" do
        tracking_info = fedex.track(options.merge(:uuid => uuid)).first

        expect(tracking_info.events).not_to be_empty
      end

      it "fails if using an invalid package type" do
        fail_options = options

        fail_options[:package_type] = "UNKNOWN_PACKAGE"

        expect { fedex.track(options) }.to raise_error
      end

      it "allows short hand tracking number queries" do
        shorthand_options = { :tracking_number => options[:package_id] }

        tracking_info = fedex.track(shorthand_options).first

        expect(tracking_info.tracking_number).to eq(options[:package_id])
      end

      it "reports the status of the package" do
        tracking_info = fedex.track(options.merge(:uuid => uuid)).first

        expect(tracking_info.status).not_to be_nil
      end

    end

    context "duplicate shipments with same tracking number", :vcr, :focus do
      let(:options) do
        { :package_id             => '794639352542', #shipment_tracking_number,
          :package_type           => "TRACKING_NUMBER_OR_DOORTAG",
          :include_detailed_scans => true
        }
      end
      let(:mps) do
        { package_count: 2, total_weight: { value: '4', units: 'LB' }, sequence_number: '1' }
      end
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
      let(:first_shipment) do
        fedex.ship({ :shipper => shipper,
                     :recipient => recipient,
                     :mps => mps,
                     :packages => packages,
                     :service_type => "FEDEX_GROUND",
                     :filename => filename })
      end
      let(:shipment_tracking_number) do
        first_shipment[:completed_shipment_detail][:completed_package_details][:tracking_ids][:tracking_number]
      end

      it "should return tracking information for all shipments associated with tracking number" do
        second_package_mps = mps.merge(sequence_number: '2', master_tracking_id: first_shipment[:completed_shipment_detail][:master_tracking_id])
        fedex.ship({ :shipper => shipper, :recipient => recipient, :mps => second_package_mps, :packages => packages,
                     :service_type => "FEDEX_GROUND", :filename => filename })
        tracking_info = fedex.track(options)

        expect(tracking_info.length).to be > 1
      end
    end
  end
end
