require "spec_helper"

describe AttendeesController do

  context "as a visitor" do
    describe "#create" do
      it "is forbidden for visitors" do
        attrs = FactoryGirl.attributes_for :attendee
        expect { post :create, attendee: attrs, year: attrs[:year]
          }.to_not change{ Attendee.count }
        response.should be_forbidden
      end
    end

    describe "#index" do
      render_views

      it "succeeds" do
        get :index, :year => Time.now.year
        response.should be_successful
      end

      it "lists attendees with at least one plan" do
        p = FactoryGirl.create :plan
        a = FactoryGirl.create :attendee, {plans: [p]}
        a2 = FactoryGirl.create :attendee, {plans: []}
        get :index, year: a.year
        response.should be_successful
        assigns(:attendees).should include(a)
        assigns(:attendees).should_not include(a2)
      end
    end

    describe "#new" do
      it "is forbidden" do
        get :new, :year => Time.now.year
        response.should be_forbidden
      end
    end
  end

  context "as a user" do
    let!(:attendee) { FactoryGirl.create :attendee }
    let!(:user) { attendee.user }
    before do
      sign_in user
    end

    describe "#create" do
      it "given invalid attributes it does not create attendee" do
        attrs = FactoryGirl.attributes_for :attendee
        attrs[:gender] = "zzzz" # invalid, obviously
        expect {
          post :create, attendee: attrs, year: attrs[:year]
        }.to_not change{ Attendee.count }
        assigns(:attendee).errors.should_not be_empty
      end

      it "minors can specify the name of their guardian" do
        attrs = FactoryGirl.attributes_for :minor
        attrs[:guardian_full_name] = "Mommy Moo"
        expect {
          post :create, attendee: attrs, year: attrs[:year]
        }.to change{ Attendee.count }.by(+1)
      end
    end

    describe "#destroy" do
      it "destroys the attendee" do
        expect {
          delete :destroy, :id => attendee.id, :year => attendee.year
        }.to change{ user.attendees.count }.by(-1)
        response.should redirect_to user_path(user)
      end
    end

    describe "#edit" do
      context "terminus page" do
        it "is successful" do
          get :edit, year: attendee.year, id: attendee.id, page: :terminus
          response.should be_success
        end
      end
    end

    describe "#index" do
      it "excludes attendees with zero plans" do
        a1 = FactoryGirl.create :attendee
        a2 = FactoryGirl.create :attendee
        a1.plans << FactoryGirl.create(:plan)
        get :index, year: a1.year
        assigns(:attendees).should_not include(a2)
      end
    end

    describe "#show" do
      it "will not show attendees from the wrong year" do
        atnd = FactoryGirl.create :attendee, :year => 2012
        admin = FactoryGirl.create :admin, :year => 2012
        sign_in admin
        expect { get :show, :id => atnd.id, :year => 2011
          }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    describe "#update" do

      def put_update attendee_attrs
        put :update,
          attendee: attendee_attrs,
          id: attendee.id,
          page: 'basics',
          year: attendee.year
      end

      def datetime_attrs arpt_date, arpt_time
        {
          :airport_arrival_date => arpt_date,
          :airport_arrival_time => arpt_time
        }
      end

      it "updates a trivial field" do
        expect { put_update :given_name => 'banana'
          }.to change { attendee.reload.given_name }
      end

      it "updates valid airport datetimes" do
        d = "#{attendee.year}-01-01"
        put_update datetime_attrs(d, "8:00 PM")
        attendee.reload.airport_arrival.should be_present
        attendee.airport_arrival.strftime("%Y-%m-%d %H:%M").should == "#{d} 20:00"
      end

      it "does not update invalid airport date" do
        put_update datetime_attrs("1/1/#{attendee.year}", "8:00 PM")
        attendee.reload.airport_arrival.should be_nil
        assigns(:attendee).errors[:base].should_not be_empty
      end

      it "does not update invalid airport time" do
        valid_date = "#{attendee.year}-01-01"
        put_update datetime_attrs(valid_date, "7:77 PM")
        attendee.reload.airport_arrival.should be_nil
        assigns(:attendee).errors[:base].should_not be_empty
      end

      it "does not update admin fields" do
        put_update :comment => 'banana'
        response.should be_forbidden
      end

    end
  end
end
