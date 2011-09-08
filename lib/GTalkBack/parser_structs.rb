# A conversation has a field, chats, containing either an Email or an array containing chats.
# A chat has an array, messages, containing one or more Messages or DateBreaks
module Gtalkback
  Conversation = Struct.new(:subject, :date, :chats, :id)
  
  Chat = Struct.new(:subject, :date, :messages)
  Email = Struct.new(:content, :date, :subject)
  
  Message = Struct.new(:content, :time, :username)
  DateBreak = Struct.new(:time)
end
