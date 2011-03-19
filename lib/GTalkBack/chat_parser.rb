require 'nokogiri'

# =======================================================================================
# A note on speed vs. fragility:
# Because using css selectors is so slow, in many cases we manually walk the DOM, doing
# quick sanity checks here and there to make sure the element we expect to be the second
# child of the first child of the <body> (or whatever) is what we expect it to be. By
# eliminating CSS calls, we run in 30% of the time as with them. But, of course, if
# Google's DOM changes even slightly, the whole thing breaks. On the other hand, CSS
# selectors weren't much better; because Google used inline styles rather than classes,
# IDs, etc., we had to do things like select all the DIVs and presume they're all message
# items, or that 'span > span > span', should it exist, is a username.
# =======================================================================================

# Nokogiri convienence method
# class String
#   def html_strip
#     self.gsub(/^[\302\240|\s]*|[\302\240|\s]*$/, '')
#   end
# end

module Gtalkback
  class ChatParser
    def self.parse(text)
      # Parse the text for messages and date breaks.
      chat_xml = Nokogiri::HTML(text)
      messages = Array.new(chat_xml.root.first_element_child.children.length)

      # For each element, break it up into its sub-elements (content, time, username, etc.)
      Array.new(chat_xml.root.first_element_child.children.length) do |index|
        log_item = chat_xml.root.first_element_child.children[index]

        # Our items can either be div, showing a logged message ...
        if(log_item.name == 'div' &&
           log_item.children.size == 2 &&
           log_item.first_element_child.name == 'span' &&
           log_item.first_element_child.attribute('style') &&
           log_item.first_element_child.attribute('style').value ==
           'display:block;float:left;color:#888') then
           
          message = Gtalkback::Message.new

          message.time = log_item.first_element_child.content

          # If we see a username in the current log_item, start a new log_group
          # div in the output
          if ((username_source = log_item.children[1].first_element_child.first_element_child) &&
               username_source.attribute('style') &&
              (username_source.attribute('style').value == 'font-weight:bold')) then
            message.username = username_source.content
            
            # Remove it to get clean content
            username_source.remove
            # Also must remove the ': ' after the username
            message.content = log_item.children[1].first_element_child.inner_html[2..-1]
          else
            # If we don't have a valid username, don't clean the source
            message.content = log_item.children[1].first_element_child.inner_html
          end
          
          message
          
        # ... or a table holding a timestamp break ...
        elsif(log_item.name == 'table' &&
              log_item.first_element_child.first_element_child &&
              log_item.first_element_child.first_element_child.attribute('style').value ==
              'font-size:1;width:100%') then
          Gtalkback::DateBreak.new(log_item.first_element_child.children[1].content)
        # ... Or some unknown thing (just output it unaltered)
        else
          #p "Error: unknown message type found"
        end

      end
      # and add it to our chat
    end
  end
end
