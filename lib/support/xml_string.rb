module Babushka
  class XMLString < String
    # This extracts values from XML, like that found in .plist files. For example,
    #
    #   %Q{
    #     <key>SVNPath</key>
    #     <string>/trunk/src</string>
    #     <key>SVNRevision</key>
    #     <string>37609</string>
    #   }.val_for('SVNRevision') #=> "37609"
    #
    # It doesn't work for arrays, and probably doesn't work for boolean values.
    # Patches welcome :)
    def val_for key
      split(/<\/[^>]+>\n\s*<key>/m).select {|i|
        i[/#{Regexp.escape(key)}<\/key>/]
      }.map {|i|
        i.scan(/<[^\/>]+>(.*)$/m)
      }.flatten.first
    end
  end
end

class String
  def xml_val_for key
    XMLString.new(self).val_for(key)
  end
end
