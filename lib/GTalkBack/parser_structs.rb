module Gtalkback
  Conversation = Struct.new(:subject, :date, :chats, :id)
  Chat = Struct.new(:subject, :date, :messages)
  Message = Struct.new(:content, :time, :username)
  DateBreak = Struct.new(:time)
end
