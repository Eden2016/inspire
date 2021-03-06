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

describe SecondaryMessagesChannel do
  its "factory works" do
    expect(build(:secondary_messages_channel)).to be_valid
  end
  describe "#" do
    let(:user) {create(:user)}
    let(:channel) {create(:secondary_messages_channel)}
    subject {channel}
    its(:has_schedule?) {should be_falsey}
    its(:sequenced?) { should be_falsey}
    its(:broadcastable?) { should be_falsey}
    its(:type_abbr){should == 'Secondary'} 
    it "group_subscribers_by_message groups messages with pending_send" do
      s1 = create(:subscriber,user:user)
      s2 = create(:subscriber,user:user)
      other_channel = create(:channel,user:user)
      other_channel.subscribers << [s1,s2]
      orig_message = create(:message,channel:other_channel)
      options = {
        :subscriber_ids => [s1.id,s2.id],
        :message_id=>orig_message.id
      }
      m1 = create(:message,channel:channel,next_send_time:1.day.ago,options:options)
      m2 = create(:message,channel:channel,next_send_time:1.minute.ago,options:options)
      m3 = create(:message,channel:channel,options:options)

      msh = subject.group_subscribers_by_message
      expect(msh.length).to eq 1
      expect(msh[m2.id].to_a).to match_array [s1,s2]
    end 
    it "group_subscribers_by_message does not include messages for which subscriber response has been received" do
      s1 = create(:subscriber,user:user)
      s2 = create(:subscriber,user:user)
      other_channel = create(:channel,user:user)
      other_channel.subscribers << [s1,s2]
      orig_message1 = create(:message,channel:other_channel)
      orig_message2 = create(:message,channel:other_channel)
      options1 = {
        :subscriber_ids => [s1.id,s2.id],
        :message_id=>orig_message1.id
      }
      options2 = {
        :subscriber_ids => [s1.id,s2.id],
        :message_id=>orig_message2.id
      }
      m1 = create(:message,channel:channel,next_send_time:1.day.ago,options:options1)
      m2 = create(:message,channel:channel,next_send_time:1.minute.ago,options:options2)
      m3 = create(:message,channel:channel,options:options2)

      create(:subscriber_response,message:orig_message1,subscriber:s1)
      msh = subject.group_subscribers_by_message
      expect(msh.length).to eq 1
      expect(msh[m2.id].to_a).to match_array [s1,s2]
      expect(subject.messages.count).to eq 3
      create(:subscriber_response,message:orig_message1,subscriber:s2)
      msh = subject.group_subscribers_by_message
      expect(msh.length).to eq 1
      expect(msh[m2.id].to_a).to match_array [s1,s2]
    end  
       
    it "perform_post_send_ops removes the messages from the channel" do
      m1 = create(:message,channel:channel,next_send_time:1.day.ago)
      m2 = create(:message,channel:channel,next_send_time:2.days.ago)
      subject.perform_post_send_ops({m1.id=>[],m2.id=>[]})
      subject.reload
      expect(subject.messages.count).to eq 0
    end
  end
end
