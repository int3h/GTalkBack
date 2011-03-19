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