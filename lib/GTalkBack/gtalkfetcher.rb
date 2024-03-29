require 'sqlite3'
require 'GTalkBack/chat_parser.rb'

module Gtalkback

  class GTalkFetcher
    CHAT_LABEL = '9'		# Numerical index of the label GMail applies to all chats
    CHATS_QUERY ='
  		SELECT 
  			MessagesFT_content.c1Body AS chat_content,
  			Messages.dateMs AS chat_date,
  			MessagesFT_content.c0Subject AS chat_subject,
  			Conversations.FirstDateMs AS conversation_date,
  			Conversations.Subject AS conversation_subject,
  			Conversations.ConversationId as id
  		FROM
  			Conversations
  		INNER JOIN
  			Messages ON Conversations.ConversationId = Messages.ConversationId
  		INNER JOIN 
  			MessagesFT_content ON Messages.MessageId = MessagesFT_content.rowid
  		INNER JOIN
  			ConversationLabels ON ConversationLabels.ConversationId = Conversations.ConversationId
  		WHERE 
  			ConversationLabels.LabelId = ' + CHAT_LABEL + '
  		ORDER BY
  			Conversations.ConversationId '
    NUM_OF_CONVERSATIONS_QUERY = 'SELECT COUNT(*)
  		FROM Conversations 
  		INNER JOIN ConversationLabels 
  			ON ConversationLabels.ConversationId = Conversations.ConversationId 
  		WHERE ConversationLabels.LabelId = ' + CHAT_LABEL

    def initialize(database_file)
      @db_file = database_file
    end

    def fetch_records(&tick_callback)
      results = retrieve_records

      records = Array.new(retrieve_number_of_conversations)
      index = -1
      results.each do |row|
        if(index == -1 || records[index].id != row['id']) then
          index += 1
          
          # Create a new conversation, add our current message to it
          new_convo = Gtalkback::Conversation.new(row['conversation_subject'], row['conversation_date'], Array.new, row['id'])
          messages = Gtalkback::ChatParser.parse(row['chat_content']);
          
          if(messages.is_a?(Array)) then
            # Parse message, add it to conversation
            chat = Gtalkback::Chat.new
            chat.subject = row['chat_subject']
            chat.date = row['chat_date']
            chat.messages = messages
            new_convo.chats << chat
          # If this is an e-mail reply . . .
          elsif(messages.is_a?(String)) then
            reply = Gtalkback::Email.new
            reply.subject = row['chat_subject']
            reply.date = row['chat_date']
            reply.content = messages
            new_convo.chats << reply
            puts "Encoded an e-mail: " + new_convo.chats.class.to_s
          end
          
          records[index] = new_convo
          
          # Update our caller on our progress
          yield row['chat_subject'] if block_given?
        else
          # add on our current message to the current conversation
          chat = Gtalkback::Chat.new
          chat.subject = row['chat_subject']
          chat.date = row['chat_date']
          chat.messages = Gtalkback::ChatParser.parse(row['chat_content'])
          records[index].chats << chat
        end
      end
      return records
    end
  
    def retrieve_number_of_conversations()
      count = nil
      connect_to_db do |db|
        #count = db.get_first_value(NUM_OF_CONVERSATIONS_QUERY)
        return db.get_first_value(NUM_OF_CONVERSATIONS_QUERY)
      end
      return count
    end
  
  private

    def retrieve_records
      rows = nil
      connect_to_db do |db|
        rows = retrieve_chats(db)
      end
      return rows
    end

    def retrieve_chats(db)
      db.execute(CHATS_QUERY)
    end

    def connect_to_db
      db = SQLite3::Database.new(@db_file)
      db.results_as_hash = true
      yield db
      db.close
    end
  end

end