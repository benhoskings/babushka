require 'spec_helper'

describe Babushka::XMLString do
  it "should parse xml like a son of a bitch" do
    expect(sample_xml.val_for('CFBundleShortVersionString')).to eq('5.0.310.0')
    expect(sample_xml.val_for('CFBundleSignature')).to eq('Cr24 Example String')
    expect(sample_xml.val_for('SVNRevision')).to eq('37609')
  end
end

def sample_xml
  Babushka::XMLString.new %Q{
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
    	<key>CFBundleExecutable</key>
    	<string>Chromium</string>
    	<key>CFBundleIconFile</key>
    	<string>app.icns</string>
    	<key>CFBundleIdentifier</key>
    	<string>org.chromium.Chromium</string>
    	<key>CFBundleInfoDictionaryVersion</key>
    	<string>6.0</string>
    	<key>CFBundleName</key>
    	<string>Chromium</string>
    	<key>CFBundlePackageType</key>
    	<string>APPL</string>
    	<key>CFBundleShortVersionString</key>
    	<string>5.0.310.0</string>
    	<key>CFBundleSignature</key>
    	<string>Cr24 Example String</string>
    	<key>CFBundleURLTypes</key>
    	<array>
    		<dict>
    			<key>CFBundleURLName</key>
    			<string>Web site URL</string>
    			<key>CFBundleURLSchemes</key>
    			<array>
    				<string>http</string>
    				<string>https</string>
    			</array>
    		</dict>
    		<dict>
    			<key>CFBundleURLName</key>
    			<string>FTP site URL</string>
    			<key>CFBundleURLSchemes</key>
    			<array>
    				<string>ftp</string>
    			</array>
    		</dict>
    		<dict>
    			<key>CFBundleURLName</key>
    			<string>Local file URL</string>
    			<key>CFBundleURLSchemes</key>
    			<array>
    				<string>file</string>
    			</array>
    		</dict>
    	</array>
    	<key>CFBundleVersion</key>
    	<string>310.0</string>
    	<key>LSFileQuarantineEnabled</key>
    	<true/>
    	<key>LSHasLocalizedDisplayName</key>
    	<string>1</string>
    	<key>LSMinimumSystemVersion</key>
    	<string>10.5.0</string>
    	<key>NSAppleScriptEnabled</key>
    	<true/>
    	<key>SVNPath</key>
    	<string>/trunk/src</string>
    	<key>SVNRevision</key>
    	<string>37609</string>
    	<key>UTExportedTypeDeclarations</key>
    	<array>
    		<dict>
    			<key>UTTypeConformsTo</key>
    			<array>
    				<string>public.data</string>
    			</array>
    			<key>UTTypeDescription</key>
    			<string>Chromium Extra</string>
    			<key>UTTypeIdentifier</key>
    			<string>org.chromium.extension</string>
    			<key>UTTypeTagSpecification</key>
    			<dict>
    				<key>public.filename-extension</key>
    				<array>
    					<string>crx</string>
    				</array>
    			</dict>
    		</dict>
    	</array>
    </dict>
    </plist>
  }
end
