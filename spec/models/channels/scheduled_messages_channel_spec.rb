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

describe ScheduledMessagesChannel do
  its "factory works" do
    expect(build(:scheduled_messages_channel)).to be_valid
  end
  describe "#" do
    let(:user) {create(:user)}
    let(:channel){create(:scheduled_messages_channel,user:user)}
    subject { channel }
    its(:has_schedule?) {should be_truthy}
    its(:sequenced?) { should be_truthy}
    its(:broadcastable?) { should be_falsey}
    its(:type_abbr){should == 'Scheduled'}
    
    it "group_subscribers_by_message returns first message for all subscribers" do
      subscribers = (0..3).map{
        subscriber = create(:subscriber,user:user)
        channel.subscribers << subscriber
        subscriber
      }
      messages = (0..2).map{
        create(:message,channel:channel)
      }
      msh = subject.group_subscribers_by_message
      expect(msh.length).to eq 1
      msg_no,subs = msh.first
      expect(msg_no).to eq messages[0].id
      expect(subs).to match_array subscribers
    end 

    it "send_scheduled_messages sends all messages once and stops" do
      subscribers = (0..3).map{
        subscriber = create(:subscriber,user:user)
        channel.subscribers << subscriber
        subscriber
      }
      messages = (0..2).map{
        create(:message,channel:channel)
      }
      
      allow_any_instance_of(TwilioMessagingManager).to receive(:send_message).and_return(true)
      expect{subject.send_scheduled_messages}.to change{DeliveryNotice.count}.by(4)
      expect{subject.send_scheduled_messages}.to change{DeliveryNotice.count}.by(4)
      expect{subject.send_scheduled_messages}.to change{DeliveryNotice.count}.by(4)
      expect{subject.send_scheduled_messages}.to change{DeliveryNotice.count}.by(0)
    end
  end
end
