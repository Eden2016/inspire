# == Schema Information
#
# Table name: channels
#
#  id                       :integer          not null, primary key
#  name                     :string(255)
#  description              :text
#  user_id                  :integer
#  type                     :string(255)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  keyword                  :string(255)
#  tparty_keyword           :string(255)
#  next_send_time           :datetime
#  schedule                 :text
#  channel_group_id         :integer
#  one_word                 :string(255)
#  suffix                   :string(255)
#  moderator_emails         :text
#  real_time_update         :boolean
#  deleted_at               :datetime
#  relative_schedule        :boolean
#  send_only_once           :boolean          default(FALSE)
#  active                   :boolean          default(TRUE)
#  allow_mo_subscription    :boolean          default(TRUE)
#  mo_subscription_deadline :datetime
#

class OnDemandMessagesChannel < Channel
  def self.system_channel?
    false
  end

  def has_schedule?
    false
  end

  # Defines whether the move-up and move-down actions make any sense.
  def sequenced?
    false
  end

  def broadcastable?
    false
  end

  def type_abbr
    "On Demand"
  end

  def individual_messages_have_schedule?
    false
  end

  def reset_next_send_time
    self.next_send_time = 10.years.from_now
    save!
  end

  def process_custom_channel_command(subscriber_response)
    handle_user_message subscriber_response
  end

  def handle_user_message(subscriber_response)
    subscriber = nil
    if subscriber_response.subscriber.present?
      if channel_group&.all_channel_subscribers&.include?(subscriber_response.subscriber) ||
        subscribers&.include?(subscriber_response.subscriber)

        subscriber = subscriber_response.subscriber
      end
    end

    return false unless subscriber

    if subscriber_response.content_text.strip =~ /^#{one_word}$/i
      send_random_message subscriber
      true
    else
      false
    end
  end

  def send_random_message(subscriber)
    pending_messages = pending_messages_ids(subscriber)
    if pending_messages.empty? && !send_only_once
      pending_messages = messages.select(:id).map(&:id)
    end

    message_id = pending_messages.sample
    return unless message_id

    message = messages.find(message_id)
    return unless message

    MessagingManager.init_instance.broadcast_message message, [subscriber]
    message.send_to_subscribers [subscriber] if message
  end
end
