require 'rails_helper'

describe TimePickerInput do
  it "#input " do
    expect(TimePickerInput.new(double.as_null_object,
      double.as_null_object,double.as_null_object,
      double.as_null_object).input({})).to_not be_nil
  end
end