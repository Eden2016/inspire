require 'rails_helper'

describe UsersController do
  describe "routing" do

    it "routes to #show" do
      expect(get("users/2")).to route_to controller:'users',action:'show',:id=>'2'
    end
  end
end