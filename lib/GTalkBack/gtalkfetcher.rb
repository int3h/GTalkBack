require 'sqlite3'

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
      index = nil
      results.each do |row|
        if(index == nil || records[index].id != row['id']) then
          # Create a new conversation, add our current message to it
        else
          # add on our current message to the current record
        end
        # TODO: Make this fire only on new conversations, and show the conversation subject and date
        # TODO: Create a way for the caller to find the total # of convos so they can increment a progress bar
        yield row['chat_subject'] if block_given?
      end
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