module ChannelsHelper
  def channel_types
    Channel.child_classes.map { |klass| klass.to_s.to_sym }
  end

  def user_channel_types
    Channel.child_classes.select { |c| !c.system_channel? }.map { |c| c.to_s.to_sym }
  end

  def channel_schedulable?(channel_type)
    case channel_type
    when  "AnnouncementsChannel",
          "OnDemandMessagesChannel",
          "IndividuallyScheduledMessagesChannel"
      false
    when  "OrderedMessagesChannel",
          "RandomMessagesChannel",
          "ScheduledMessagesChannel"
      true
    else
      false
    end
  end

  def message_subtext(channel, message, index)
    if channel.individual_messages_have_schedule?
      if channel.relative_schedule?
        return content_tag(:div, message.schedule, class: "small").html_safe
      elsif message.next_send_time
        return content_tag(
          :div,
          message.next_send_time.strftime("%c"),
          class: "small",
        ).html_safe
      else
        return nil
      end
    end

    if channel.sequenced? && channel.has_schedule?
      schedule = channel.converted_schedule
      if schedule
        return content_tag(
          :div,
          schedule.next_occurrences(index + 1)[index].strftime("%c"),
          class: "small",
        ).html_safe
      end
      nil
    end
  end
end
