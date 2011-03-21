module Gtalkback
  class NokChatFormatter
    def self.format_conversation(conversation)
      # Build a new HTML document, which we'll populate with bits from the original logs
      output = Nokogiri::HTML::Builder.new do |doc|
        doc.html {
          doc.head {
            doc.title conversation.subject
            doc.link(:rel => 'stylesheet', :href => "style.css", :type => 'text/css', :media => 'screen')
          }

          doc.body {
            doc.div.header {
              doc.div.title conversation.subject
            }

            conversation.chats.each do |chat|
              doc.div.content {
                doc.div(:class => 'date') {
                  doc.text Time.at(chat.date/1000).strftime('%A, %B %d, %Y') # at %I:%M %p
                }

                doc.div.logs {

                  # Holds a reference to the last div.message created so we can shove all
                  # our messages into it.
                  # Assumes that there will always be a username given to us before we get to
                  # our first message so we can initialize this. Kinda a gamble, but oh well.
                  current_log_group = nil

                  # Now build our log items from our original message
                  # (this command selects all the children of the first element, 
                  # <body>, created implcitly by Nokogiri to make proper html.)
                  chat.messages.each do |message|
                    if(message.is_a?(Gtalkback::Message)) then
                      # If we see a username in the current message, start a new log_group 
                      # div in the output
                      if (message.username) then
                        css_scrubbed_username = message.username.gsub(/[^0-9a-zA-Z_-]/, '')
                        doc.div(:class => ('log_group ' + css_scrubbed_username)) {
                          current_log_group = doc.parent
                          # And, while we're here, put in the username
                          doc.span.username message.username
                        }
                      else 
                        # If we don't have a valid username, indicate as such
                        username_source = nil
                      end

                      # Write out our actually timestamp & message, building it seperately
                      # and attaching it to the current log_group
                      Nokogiri::XML::Builder.with(current_log_group) do |xml|
                        xml.div.log_item {
                          xml.span.timestamp  message.time

                          xml.span.message {
                            xml.parent.inner_html = message.content
                          }

                        }
                      end

                      # ... or a table holding a timestamp break ...  
                    elsif(message.is_a?(Gtalkback::DateBreak)) then
                      doc.div.timebreak {
                        span.time message.time
                      }
                      # ... Or some unknown thing (just output it unaltered)
                    elsif(message.is_a?(Gtalkback::Email))
                      # doc.parent.add_child message
                    end
                  end
                }
              }
            end
          }
        }
      end
      
      output.to_html
    end

    private

    def initialize
    end
  end
end