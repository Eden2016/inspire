# == Schema Information
#
# Table name: channels
#
#  id                :integer          not null, primary key
#  name              :string(255)
#  description       :text
#  user_id           :integer
#  type              :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  keyword           :string(255)
#  tparty_keyword    :string(255)
#  next_send_time    :datetime
#  schedule          :text
#  channel_group_id  :integer
#  one_word          :string(255)
#  suffix            :string(255)
#  moderator_emails  :text
#  real_time_update  :boolean
#  deleted_at        :datetime
#  relative_schedule :boolean
#  send_only_once    :boolean          default(FALSE)
#

require 'rails_helper'

describe OnDemandMessagesChannel do
  its "factory works" do
    expect(build(:on_demand_messages_channel)).to be_valid
  end
  describe "#" do
    let(:user){create(:user)}
    let(:channel){create(:on_demand_messages_channel,user:user,
      one_word:Faker::Lorem.word)}
    subject { channel }
    its(:has_schedule?) {should be_falsey}
    its(:sequenced?) { should be_falsey}
    its(:broadcastable?) { should be_falsey}
    its(:type_abbr){should == 'On Demand'}
    it "reset_next_send_time resets next_send_time to 10 years" do
      subject.reset_next_send_time 
      expect(subject.next_send_time).to be > 9.years.from_now
    end
    
    describe "handle_user_message" do
      before do
        @my_sub = create(:subscriber,user:user)
        channel.subscribers << @my_sub        
      end
      it "triggers a message send for the subscriber if empty" do
        subscriber_response = create(:subscriber_response,
          subscriber:@my_sub,channel:channel,caption:"#{channel.one_word}")
        expect(subject).to receive(:send_random_message){|subscriber|
          expect(subscriber).to eq @my_sub
        }
        subject.handle_user_message(subscriber_response)
      end
      it "does not trigger message send for non empty user comments" do
        subscriber_response = create(:subscriber_response,
          subscriber:@my_sub,channel:channel,caption:'some text')
        expect(subject).to_not receive(:send_random_message)
        subject.handle_user_message(subscriber_response)
      end
    end

    describe "send_random_message" do
      it "sends unsent messages in random order" do
        subscriber = create(:subscriber,user:user)
        channel.subscribers << subscriber
        messages = (0..3).map{
          create(:message,channel:channel)
        }
        allow_any_instance_of(TwilioMessagingManager).to receive(:send_message).and_return(true)
        expect{
          (0..3).each{
            subject.send_random_message(subscriber)
          }
        }.to change{DeliveryNotice.count}.by(4)
      end
    end
  end
end
